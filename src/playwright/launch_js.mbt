///| Browser process launcher (JS target)

///| Uses chromium-bidi's WebSocketServer for full BiDi protocol support.

///|
/// Launch chromium-bidi WebSocket server and create a BiDi session.
/// Returns the BiDi WebSocket URL (ws://localhost:PORT/session/ID).
extern "js" fn ffi_launch_browser_process(
  headless : Bool,
) -> @js_async.Promise[String] =
  #| async (headless) => {
  #|   const { existsSync } = await import('node:fs');
  #|   const { WebSocketServer } = await import('chromium-bidi/bidiServer/WebSocketServer.js');
  #|   const cp = await import('node:child_process');
  #|
  #|   const candidates = [
  #|     process.env.CHROME_PATH,
  #|     process.env.BROWSER_BIN,
  #|     '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  #|     '/Applications/Chromium.app/Contents/MacOS/Chromium',
  #|     '/usr/bin/google-chrome',
  #|     '/usr/bin/google-chrome-stable',
  #|     '/usr/bin/chromium',
  #|     '/usr/bin/chromium-browser',
  #|     '/snap/bin/chromium',
  #|   ].filter(Boolean);
  #|
  #|   let chromeBinary = null;
  #|   for (const p of candidates) {
  #|     if (existsSync(p)) { chromeBinary = p; break; }
  #|   }
  #|   if (!chromeBinary) {
  #|     throw new Error('Chrome/Chromium not found. Set CHROME_PATH env var.');
  #|   }
  #|   process.env.BROWSER_BIN = chromeBinary;
  #|
  #|   const port = 9990 + Math.floor(Math.random() * 1000);
  #|   const server = new WebSocketServer(port, false);
  #|
  #|   if (!globalThis.__pw_chrome_pids) globalThis.__pw_chrome_pids = new Set();
  #|
  #|   // Register synchronous exit handler once
  #|   if (!globalThis.__pw_exit_registered) {
  #|     globalThis.__pw_exit_registered = true;
  #|     const killAll = () => {
  #|       for (const pid of (globalThis.__pw_chrome_pids || [])) {
  #|         try { process.kill(pid, 'SIGKILL'); } catch {}
  #|       }
  #|     };
  #|     process.on('exit', killAll);
  #|     process.on('SIGINT', () => { killAll(); process.exit(130); });
  #|     process.on('SIGTERM', () => { killAll(); process.exit(143); });
  #|   }
  #|
  #|   await new Promise(r => setTimeout(r, 500));
  #|
  #|   const sessionResp = await fetch(`http://127.0.0.1:${port}/session`, {
  #|     method: 'POST',
  #|     headers: { 'Content-Type': 'application/json' },
  #|     body: JSON.stringify({
  #|       capabilities: {
  #|         alwaysMatch: {
  #|           'goog:chromeOptions': {
  #|             binary: chromeBinary,
  #|             args: headless ? ['--headless=new'] : [],
  #|           },
  #|         },
  #|       },
  #|     }),
  #|   });
  #|
  #|   const sessionData = await sessionResp.json();
  #|   const wsUrl = sessionData.value?.capabilities?.webSocketUrl;
  #|   if (!wsUrl) {
  #|     throw new Error('Failed to create BiDi session: ' + JSON.stringify(sessionData));
  #|   }
  #|
  #|   // Track Chrome PIDs spawned by chromium-bidi
  #|   try {
  #|     const output = cp.execSync(
  #|       "pgrep -f 'chrome.*--remote-debugging-pipe' 2>/dev/null || true",
  #|       { encoding: 'utf8' }
  #|     ).trim();
  #|     for (const line of output.split('\n')) {
  #|       const pid = parseInt(line, 10);
  #|       if (pid > 0) globalThis.__pw_chrome_pids.add(pid);
  #|     }
  #|   } catch {}
  #|
  #|   return wsUrl;
  #| }

///|
/// Close all BiDi servers and kill spawned Chrome processes
extern "js" fn ffi_kill_browser_processes() -> Unit =
  #| () => {
  #|   for (const pid of (globalThis.__pw_chrome_pids || [])) {
  #|     try { process.kill(pid, 'SIGKILL'); } catch {}
  #|   }
  #|   if (globalThis.__pw_chrome_pids) globalThis.__pw_chrome_pids.clear();
  #| }

///|
/// Launch browser process and return BiDi WS endpoint URL
async fn launch_browser_process(headless : Bool) -> String {
  ffi_launch_browser_process(headless).wait()
}
