const { execFile } = require("node:child_process")
const { once } = require("node:events")
const path = require("node:path")
const { promisify } = require("node:util")
const { chromium, test } = require("@playwright/test")
const { WebSocketServer, WebSocket } = require("ws")

const run = promisify(execFile)
const repoRoot = path.resolve(__dirname, "../..")

test.beforeAll(async () => {
  await run("moon", ["build", "src/playwright/test_utils/dom_bridge", "--target", "js"], { cwd: repoRoot })
})

// Use the real BiDi mapper, with a browser owned and closed by each test.
// This exercises the published MoonBit API and the JavaScript it sends to DOM.
for (const scenario of ["content", "labels", "text"]) {
  test(`MoonBit locators read and interact with DOM: ${scenario}`, async () => {
    test.setTimeout(30_000)
    const { BrowserInstance } = await import("chromium-bidi/bidiServer/BrowserInstance.js")
    const browser = await BrowserInstance.run({
      chromeBinary: chromium.executablePath(),
      chromeArgs: ["--headless=new"],
    }, false)
    const server = new WebSocketServer({ host: "127.0.0.1", port: 0 })
    try {
      await once(server, "listening")
      const transport = browser.bidiSession()
      server.on("connection", socket => {
        const onMessage = message => {
          if (socket.readyState === WebSocket.OPEN) socket.send(message)
        }
        transport.on("message", onMessage)
        socket.on("close", () => transport.off("message", onMessage))
        socket.on("message", data => {
          const command = JSON.parse(data.toString())
          // Session lifetime belongs to this fixture; the mapper handles DOM commands.
          if (command.method === "session.end") {
            socket.send(JSON.stringify({ id: command.id, type: "success", result: {} }))
            return
          }
          transport.sendCommand(data.toString()).catch(error => {
            if (socket.readyState === WebSocket.OPEN) {
              socket.send(JSON.stringify({ id: command.id, type: "error", error: "unknown error", message: error.message }))
            }
          })
        })
      })
      const endpoint = `ws://127.0.0.1:${server.address().port}`
      try {
        await run(process.execPath, ["--enable-source-maps", "_build/js/debug/build/test_utils/dom_bridge/dom_bridge.js", endpoint, scenario], {
          cwd: repoRoot,
          timeout: 20_000,
        })
      } catch (error) {
        throw new Error(`${error.message}\n${error.stdout ?? ""}\n${error.stderr ?? ""}`)
      }
    } finally {
      for (const socket of server.clients) socket.terminate()
      await new Promise(resolve => server.close(resolve))
      await browser.close()
    }
  })
}
