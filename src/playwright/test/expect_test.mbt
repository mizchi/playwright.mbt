///|
fn assert_failure(f : () -> Unit raise) -> Unit raise {
  let failed = try {
    f()
    false
  } catch {
    _ => true
  }
  assert_eq(failed, true)
}

///|
test "expect to_be and to_equal" {
  expect(1).to_be(1)
  expect("a").to_equal("a")
}

///|
test "expect to_match" {
  expect("hello").to_match("h.llo")
}

///|
test "expect to_match supports non-capturing group" {
  expect("ab").to_match("(?:a)b")
}

///|
test "expect failure" {
  assert_failure(fn() { expect(1).to_be(2) })
  assert_failure(fn() { expect("hello").to_match("z+") })
}

///|
test "expect to_contain and to_have_length" {
  expect("hello world").to_contain("world")
  expect("hello").to_have_length(5)
}

///|
test "expect array helpers" {
  expect([1, 2, 3]).to_contain_item(2)
  expect([1, 2, 3]).to_have_length_items(3)
}

///|
test "expect numeric comparisons" {
  expect(3).to_be_greater_than(2)
  expect(2).to_be_less_than(3)
  expect(3.1415).to_be_close_to(3.14, precision=2)
}

///|
test "expect truthy and falsy" {
  expect(true).to_be_truthy()
  expect(false).to_be_falsy()
}

///|
async test "retry helper in playwright/test" {
  let attempts : Ref[Int] = { val: 0, }
  let value = retry(times=3, async fn() -> Int {
    attempts.val = attempts.val + 1
    if attempts.val < 3 {
      assert_eq(true, false, msg="transient failure")
    }
    attempts.val
  })
  assert_eq(value, 3)
}

///|
test "shard helper in playwright/test" {
  let hit : Ref[Int] = { val: 0, }
  shard(item_index=0, item_total=2, shard_index=1, shard_total=2, fn() {
    hit.val = hit.val + 1
  })
  shard(item_index=1, item_total=2, shard_index=1, shard_total=2, fn() {
    hit.val = hit.val + 1
  })
  assert_eq(hit.val, 1)
}

///|
async test "timeout helper in playwright/test" {
  let value = timeout(ms=50, async fn() -> Int { 7 })
  assert_eq(value, 7)
}

///|
test "step and skip helpers in playwright/test" {
  let value = step("sync-step", fn() -> Int { 11 })
  assert_eq(value, 11)
  let hit : Ref[Int] = { val: 0, }
  skip(fn() { hit.val = hit.val + 1 })
  skip_if(condition=false, fn() { hit.val = hit.val + 1 })
  skip_if(condition=true, fn() { hit.val = hit.val + 1 })
  assert_eq(hit.val, 1)
}

///|
async test "async test helpers and to_pass in playwright/test" {
  let value = step_async("async-step", async fn() -> Int { 12 })
  assert_eq(value, 12)
  let hit : Ref[Int] = { val: 0, }
  skip_async(async fn() { hit.val = hit.val + 1 })
  skip_if_async(condition=false, async fn() { hit.val = hit.val + 1 })
  skip_if_async(condition=true, async fn() { hit.val = hit.val + 1 })
  assert_eq(hit.val, 1)
  let attempts : Ref[Int] = { val: 0, }
  to_pass(timeout=100, interval=1, async fn() {
    attempts.val = attempts.val + 1
    assert_eq(attempts.val >= 2, true, msg="retry via to_pass")
  })
  assert_eq(attempts.val, 2)
}

///|
test "fail and fixme helpers in playwright/test" {
  fail(fn() { assert_eq(1, 2) })
  fixme(fn() { assert_eq(1, 2) })
  try fail(fn() { assert_eq(1, 1) }) catch {
    _ => ()
  } noraise {
    _ => assert_eq(true, false, msg="fail should fail when block succeeds")
  }
}

///|
async test "fail_async and fixme_async helpers in playwright/test" {
  fail_async(async fn() { assert_eq(1, 2) })
  fixme_async(async fn() { assert_eq(1, 2) })
  try fail_async(async fn() { assert_eq(1, 1) }) catch {
    _ => ()
  } noraise {
    _ =>
      assert_eq(true, false, msg="fail_async should fail when block succeeds")
  }
}

///|
async test "config setup is available in playwright/test" {
  reset_test_config()
  configure_test(
    retry_times=2,
    expect_timeout_ms=20,
    expect_interval_ms=1,
    shard_index=2,
    shard_total=2,
  )
  let attempts : Ref[Int] = { val: 0, }
  let value = retry(async fn() -> Int {
    attempts.val = attempts.val + 1
    if attempts.val < 2 {
      assert_eq(true, false, msg="retry from config in test package")
    }
    attempts.val
  })
  assert_eq(value, 2)
  let hit : Ref[Int] = { val: 0, }
  shard(item_index=0, item_total=2, fn() { hit.val = hit.val + 1 })
  shard(item_index=1, item_total=2, fn() { hit.val = hit.val + 1 })
  assert_eq(hit.val, 1)
  reset_test_config()
}

///|
async test "expect_poll retries and matcher methods" {
  let attempts_int : Ref[Int] = { val: 0, }
  expect_poll(
    async fn() -> Int {
      attempts_int.val = attempts_int.val + 1
      attempts_int.val
    },
    timeout=100,
    interval=1,
  ).to_be(3)
  assert_eq(attempts_int.val, 3)
  let attempts_text : Ref[Int] = { val: 0, }
  expect_poll(
    async fn() -> String {
      attempts_text.val = attempts_text.val + 1
      if attempts_text.val < 2 {
        "pending"
      } else {
        "done value"
      }
    },
    timeout=100,
    interval=1,
  ).to_contain("done")
  expect_poll(
    async fn() -> String {
      if attempts_text.val < 3 {
        attempts_text.val = attempts_text.val + 1
        "nope"
      } else {
        "ok-123"
      }
    },
    timeout=100,
    interval=1,
  ).to_match("ok-\\d+")
}

///|
async test "expect_poll fails when timeout is reached" {
  try
    expect_poll(async fn() -> String { "pending" }, timeout=10, interval=1).to_match(
      "done",
    )
  catch {
    _ => ()
  } noraise {
    _ => assert_eq(true, false, msg="expect_poll should fail")
  }
}
