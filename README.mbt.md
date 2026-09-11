# mizchi/playwright.mbt

Playwright 互換 API を WebDriver BiDi 上に実装した MoonBit ライブラリです。
関数名は MoonBit 流儀の `snake_case` で提供します。

## 開発時の検証

`just release-check` でフォーマット・型チェック・単体テストを実行します。
ブラウザ統合テストは次の手順で実行します。

```sh
pnpm --dir test/integration install --frozen-lockfile
pnpm --dir test/integration exec playwright install chromium
just test-integration
```

統合テストは設定の受け渡しに加え、MoonBit の公開 API から実際の Chromium を
BiDi 経由で操作し、DOM の取得・ラベル検索・テキストによるクリックを検証します。

## インストール

```bash
moon add mizchi/playwright
```

## パッケージ

- `mizchi/playwright`: ブラウザ操作 API（`chromium`, `firefox`, `webkit` など）
- `mizchi/playwright/test`: `expect` とテスト DSL（`retry`, `timeout`, `to_pass`, `expect_poll`, `step`, `skip`, `fail`, `fixme`, `shard` など）

## 使い方

```mbt check
import "mizchi/playwright" as @pw
import "mizchi/playwright/test" as @pwt

let chromium = @pw.chromium()
let _ = @pwt.expect(chromium.name()).to_equal("chromium")

async test "dsl helpers" {
  @pwt.configure_test(
    retry_times=3,
    timeout_ms=3_000,
    expect_timeout_ms=800,
    expect_interval_ms=10,
    shard_index=1,
    shard_total=2,
  )

  let _ = @pwt.step("open", fn() -> Int { 1 })

  // shard は設定値を省略可能
  @pwt.shard(item_index=0, item_total=2, fn() {})

  // retry / timeout は設定値をデフォルトとして使える
  let _ = @pwt.retry(async fn() -> Int { 1 })

  let _ = @pwt.timeout(async fn() -> Int { 1 })

  // 一定時間リトライしながら assertion
  @pwt.to_pass(async fn() {
    @pwt.expect("ok").to_equal("ok")
  })

  // expect.poll 相当
  @pwt.expect_poll(async fn() -> String { "done-1" }).to_match("done-\\d+")
}
```

## Playwright 連携（1プロセス共有）

`@playwright/test` 側で `globalSetup` を使うと、ブラウザサーバーを 1 回だけ起動して `wsEndpoint` を複数テストで共有できます。

```js
// test/integration/global.setup.js
const { chromium } = require("@playwright/test")
const fs = require("node:fs/promises")
const path = require("node:path")

module.exports = async () => {
  const server = await chromium.launchServer({ headless: true })
  const runtimeDir = path.join(__dirname, ".runtime")
  await fs.mkdir(runtimeDir, { recursive: true })
  await fs.writeFile(
    path.join(runtimeDir, "state.json"),
    JSON.stringify({ ws_endpoint: server.wsEndpoint() }),
    "utf-8",
  )
  return async () => {
    await server.close()
  }
}
```

```js
// test/integration/config_bridge.spec.js (抜粋)
const state = JSON.parse(fs.readFileSync(".runtime/state.json", "utf-8"))
const wsEndpoint = state.ws_endpoint

spawnSync("moon", [
  "run",
  "src/playwright/test_utils/integration_bridge",
  "--target",
  "js",
  /* retry/timeout/shard など */,
  wsEndpoint,
])
```

このリポジトリでは上記方式を `test/integration/` で実装済みです。
