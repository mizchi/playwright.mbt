///|
async test "retry retries until callback succeeds" {
  let attempts : Ref[Int] = { val: 0, }
  let value = retry(times=3, async fn() -> Int {
    attempts.val = attempts.val + 1
    if attempts.val < 3 {
      assert_eq(true, false, msg="transient failure")
    }
    attempts.val
  })
  assert_eq(value, 3)
  assert_eq(attempts.val, 3)
}

///|
async test "retry stops at retry limit and returns failure" {
  let attempts : Ref[Int] = { val: 0, }
  try
    retry(times=2, async fn() -> Int {
      attempts.val = attempts.val + 1
      assert_eq(true, false, msg="always fail")
      0
    })
  catch {
    _ => ()
  } noraise {
    _ => assert_eq(true, false, msg="retry should fail")
  }
  assert_eq(attempts.val, 2)
}

///|
test "in_shard partitions items without overlap" {
  let shard_total = 3
  let item_total = 10
  for item_index in 0..<item_total {
    let mut assigned = 0
    for shard_index in 1..<=shard_total {
      if in_shard(item_index~, item_total~, shard_index~, shard_total~) {
        assigned = assigned + 1
      }
    }
    assert_eq(assigned, 1)
  }
}

///|
test "shard runs callback only for selected shard" {
  let hit : Ref[Int] = { val: 0, }
  shard(item_index=1, item_total=4, shard_index=1, shard_total=2, fn() {
    hit.val = hit.val + 1
  })
  shard(item_index=3, item_total=4, shard_index=1, shard_total=2, fn() {
    hit.val = hit.val + 1
  })
  assert_eq(hit.val, 1)
}

///|
async test "shard_async runs async callback only for selected shard" {
  let hit : Ref[Int] = { val: 0, }
  shard_async(item_index=0, item_total=5, shard_index=1, shard_total=2, async fn() {
    hit.val = hit.val + 1
  })
  shard_async(item_index=4, item_total=5, shard_index=1, shard_total=2, async fn() {
    hit.val = hit.val + 1
  })
  assert_eq(hit.val, 1)
}

///|
async test "timeout returns value before deadline" {
  let value = timeout(ms=50, async fn() -> Int { 42 })
  assert_eq(value, 42)
}

///|
async test "timeout fails when callback does not complete" {
  let queue : @async.Queue[Int] = @async.Queue(kind=@aqueue.Kind::Unbounded)
  try timeout(ms=1, async fn() -> Int { queue.get() }) catch {
    _ => ()
  } noraise {
    _ => assert_eq(true, false, msg="timeout should fail")
  }
}

///|
async test "to_pass retries until assertion succeeds" {
  let attempts : Ref[Int] = { val: 0, }
  to_pass(timeout=100, interval=1, async fn() {
    attempts.val = attempts.val + 1
    assert_eq(attempts.val >= 3, true, msg="not ready")
  })
  assert_eq(attempts.val, 3)
}

///|
async test "to_pass fails when timeout is reached" {
  let attempts : Ref[Int] = { val: 0, }
  try
    to_pass(timeout=10, interval=1, async fn() {
      attempts.val = attempts.val + 1
      assert_eq(true, false, msg="always fail")
    })
  catch {
    _ => ()
  } noraise {
    _ => assert_eq(true, false, msg="to_pass should fail")
  }
  assert_true(attempts.val >= 1)
}

///|
async test "slow runs async block with extended timeout wrapper" {
  let value = slow(async fn() -> Int { 10 })
  assert_eq(value, 10)
}

///|
test "step returns callback result" {
  let value = step("calculate", fn() -> Int { 5 })
  assert_eq(value, 5)
}

///|
async test "step_async returns callback result" {
  let value = step_async("calculate_async", async fn() -> Int { 6 })
  assert_eq(value, 6)
}

///|
test "skip and skip_if control execution" {
  let hit : Ref[Int] = { val: 0, }
  skip(fn() { hit.val = hit.val + 1 })
  skip_if(condition=false, fn() { hit.val = hit.val + 1 })
  skip_if(condition=true, fn() { hit.val = hit.val + 1 })
  assert_eq(hit.val, 1)
}

///|
async test "skip_async and skip_if_async control execution" {
  let hit : Ref[Int] = { val: 0, }
  skip_async(async fn() { hit.val = hit.val + 1 })
  skip_if_async(condition=false, async fn() { hit.val = hit.val + 1 })
  skip_if_async(condition=true, async fn() { hit.val = hit.val + 1 })
  assert_eq(hit.val, 1)
}

///|
test "fail and fixme expect failures" {
  fail(fn() { assert_eq(1, 2) })
  fixme(fn() { assert_eq(1, 2) })
  try fail(fn() { assert_eq(1, 1) }) catch {
    _ => ()
  } noraise {
    _ => assert_eq(true, false, msg="fail should fail when block succeeds")
  }
}

///|
async test "fail_async and fixme_async expect failures" {
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
async test "config setup controls helper defaults" {
  reset_test_config()
  configure_test(
    retry_times=3,
    timeout_ms=30,
    expect_timeout_ms=40,
    expect_interval_ms=1,
    slow_timeout_ms=50,
    shard_index=2,
    shard_total=2,
  )
  let attempts : Ref[Int] = { val: 0, }
  let value = retry(async fn() -> Int {
    attempts.val = attempts.val + 1
    if attempts.val < 3 {
      assert_eq(true, false, msg="retry from config")
    }
    attempts.val
  })
  assert_eq(value, 3)
  let timeout_value = timeout(async fn() -> Int { 7 })
  assert_eq(timeout_value, 7)
  let hit : Ref[Int] = { val: 0, }
  shard(item_index=0, item_total=2, fn() { hit.val = hit.val + 1 })
  shard(item_index=1, item_total=2, fn() { hit.val = hit.val + 1 })
  assert_eq(hit.val, 1)
  try
    to_pass(async fn() { assert_eq(true, false, msg="timeout from config") })
  catch {
    _ => ()
  } noraise {
    _ => assert_eq(true, false, msg="to_pass should fail from config")
  }
  let config = current_test_config()
  assert_eq(config.retry_times, 3)
  assert_eq(config.timeout_ms, 30)
  assert_eq(config.expect_timeout_ms, 40)
  assert_eq(config.expect_interval_ms, 1)
  assert_eq(config.slow_timeout_ms, 50)
  assert_eq(config.shard_index, 2)
  assert_eq(config.shard_total, 2)
  reset_test_config()
}
