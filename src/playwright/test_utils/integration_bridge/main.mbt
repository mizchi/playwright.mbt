///|
fn parse_int_arg(args : Array[String], index : Int, name : String) -> Int {
  match args.get(index) {
    Some(value) =>
      try @string.parse_int(value.view(), base=10) catch {
        _ => @abort.abort("invalid int arg: " + name + "=" + value)
      } noraise {
        parsed => parsed
      }
    None => @abort.abort("missing required arg: " + name)
  }
}

///|
fn ensure(condition : Bool, message : String) -> Unit {
  if !condition {
    @abort.abort(message)
  }
}

///|
fn parse_string_arg(args : Array[String], index : Int, name : String) -> String {
  match args.get(index) {
    Some(value) =>
      if value.length() == 0 {
        @abort.abort("empty string arg: " + name)
      } else {
        value
      }
    None => @abort.abort("missing required arg: " + name)
  }
}

///|
async fn verify_websocket_endpoint(ws_endpoint : String) -> Unit {
  let transport = @bidi.Transport::websocket(ws_endpoint)
  let result = transport.connect()
  match result {
    Ok(_) => ()
    Err(_) => @abort.abort("failed to connect websocket endpoint")
  }
  let _ = transport.close()
}

///|
async fn verify_playwright_connection(ws_endpoint : String) -> Unit {
  let browser = @playwright.chromium().connect_over_websocket(ws_endpoint)
  ensure(browser.is_connected(), "playwright browser should be connected")
  browser.close()
}

///|
async fn run_integration_bridge() -> Unit {
  let _ = @async.now()
  let args = @env.args()
  let argc = args.length()
  ensure(argc >= 7, "expected at least 7 args")
  let offset = argc - 7
  let retry_times = parse_int_arg(args, offset + 0, "retry_times")
  let timeout_ms = parse_int_arg(args, offset + 1, "timeout_ms")
  let expect_timeout_ms = parse_int_arg(args, offset + 2, "expect_timeout_ms")
  let expect_interval_ms = parse_int_arg(args, offset + 3, "expect_interval_ms")
  let shard_index = parse_int_arg(args, offset + 4, "shard_index")
  let shard_total = parse_int_arg(args, offset + 5, "shard_total")
  let ws_endpoint = parse_string_arg(args, offset + 6, "ws_endpoint")
  ensure(
    ws_endpoint.has_prefix("ws://") || ws_endpoint.has_prefix("wss://"),
    "ws_endpoint should start with ws:// or wss://",
  )
  verify_websocket_endpoint(ws_endpoint)
  verify_playwright_connection(ws_endpoint)
  @test_utils.reset_test_config()
  @test_utils.configure_test(
    retry_times~,
    timeout_ms~,
    expect_timeout_ms~,
    expect_interval_ms~,
    shard_index~,
    shard_total~,
  )
  let attempts : Ref[Int] = { val: 0, }
  let value = try
    @test_utils.retry(async fn() -> Int {
      attempts.val = attempts.val + 1
      if attempts.val < retry_times {
        assert_eq(true, false, msg="retry configured by playwright")
      }
      attempts.val
    })
  catch {
    _ => @abort.abort("retry should eventually succeed")
  } noraise {
    v => v
  }
  ensure(value == retry_times, "retry does not use configured retry_times")
  let timeout_value = try @test_utils.timeout(async fn() -> Int { 7 }) catch {
    _ => @abort.abort("timeout should not fail for immediate callback")
  } noraise {
    v => v
  }
  ensure(timeout_value == 7, "timeout should execute successful callback")
  let hit : Ref[Int] = { val: 0, }
  @test_utils.shard(item_index=0, item_total=2, fn() { hit.val = hit.val + 1 })
  @test_utils.shard(item_index=1, item_total=2, fn() { hit.val = hit.val + 1 })
  let expected_hit = (if @test_utils.in_shard(item_index=0, item_total=2) {
      1
    } else {
      0
    }) +
    (if @test_utils.in_shard(item_index=1, item_total=2) { 1 } else { 0 })
  ensure(hit.val == expected_hit, "shard should respect configured shard")
  try
    @test_utils.to_pass(async fn() {
      assert_eq(true, false, msg="configured expect timeout")
    })
  catch {
    _ => ()
  } noraise {
    _ => @abort.abort("to_pass should fail under configured timeout")
  }
  let config = @test_utils.current_test_config()
  ensure(config.retry_times == retry_times, "retry_times mismatch")
  ensure(config.timeout_ms == timeout_ms, "timeout_ms mismatch")
  ensure(
    config.expect_timeout_ms == expect_timeout_ms,
    "expect_timeout_ms mismatch",
  )
  ensure(
    config.expect_interval_ms == expect_interval_ms,
    "expect_interval_ms mismatch",
  )
  ensure(config.shard_index == shard_index, "shard_index mismatch")
  ensure(config.shard_total == shard_total, "shard_total mismatch")
}

///|
#cfg(target="wasm")
fn main {
  let _ = run_integration_bridge
  @abort.abort("integration_bridge is not supported on wasm targets")
}

///|
#cfg(target="wasm-gc")
fn main {
  let _ = run_integration_bridge
  @abort.abort("integration_bridge is not supported on wasm-gc target")
}

///|
#cfg(target="js")
async fn main {
  run_integration_bridge()
}

///|
#cfg(target="native")
async fn main {
  run_integration_bridge()
}

///|
#cfg(target="llvm")
async fn main {
  run_integration_bridge()
}
