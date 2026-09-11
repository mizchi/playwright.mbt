///|
fn normalize_timeout_ms(timeout : Int?, fallback : Int) -> Int {
  match timeout {
    Some(value) => if value <= 0 { 1 } else { value }
    None => fallback
  }
}

///|
fn resolve_retry_times(times : Int?) -> Int {
  match times {
    Some(value) => clamp_retry_times(value)
    None => current_test_config().retry_times
  }
}

///|
fn resolve_timeout_ms(ms : Int?) -> Int {
  normalize_timeout_ms(ms, current_test_config().timeout_ms)
}

///|
fn resolve_expect_timeout_ms(timeout : Int?) -> Int {
  normalize_timeout_ms(timeout, current_test_config().expect_timeout_ms)
}

///|
fn resolve_expect_interval_ms(interval : Int?) -> Int {
  normalize_timeout_ms(interval, current_test_config().expect_interval_ms)
}

///|
fn resolve_slow_timeout_ms(timeout_ms : Int?) -> Int {
  normalize_timeout_ms(timeout_ms, current_test_config().slow_timeout_ms)
}

///|
fn resolve_shard_total(shard_total : Int?) -> Int {
  let configured = current_test_config().shard_total
  let raw = match shard_total {
    Some(value) => value
    None => configured
  }
  normalize_shard_total(raw)
}

///|
fn resolve_shard_index(shard_index : Int?, shard_total : Int) -> Int {
  let configured = current_test_config().shard_index
  let raw = match shard_index {
    Some(value) => value
    None => configured
  }
  normalize_shard_index(raw, shard_total)
}

///|
fn[T] consume(value : T) -> Unit {
  let _ = value
}

///|
async fn sleep_ms(ms : Int) -> Unit {
  if ms <= 0 {
    return
  }
  let queue : @async.Queue[Unit] = @async.Queue(kind=@aqueue.Kind::Unbounded)
  let _ = @async.with_timeout_opt(ms, async fn() -> Unit { queue.get() })
}

///|
pub async fn[T] retry(times? : Int, run : async () -> T) -> T {
  let max_attempts = resolve_retry_times(times)
  for attempt = 1 {
    try run() catch {
      error => {
        if attempt >= max_attempts {
          raise error
        }
        continue attempt + 1
      }
    } noraise {
      value => break value
    }
  }
}

///|
pub async fn[T] timeout(ms? : Int, run : async () -> T) -> T {
  let timeout_ms = resolve_timeout_ms(ms)
  @async.with_timeout(timeout_ms, run)
}

///|
pub async fn to_pass(
  run : async () -> Unit,
  timeout? : Int,
  interval? : Int,
) -> Unit {
  let timeout_ms = resolve_expect_timeout_ms(timeout)
  let interval_ms = resolve_expect_interval_ms(interval)
  let start = @async.now()
  for attempt = 0 {
    try run() catch {
      error => {
        let elapsed = (@async.now() - start).to_int()
        if elapsed >= timeout_ms {
          raise error
        }
        let remaining = timeout_ms - elapsed
        let wait_ms = if interval_ms < remaining {
          interval_ms
        } else {
          remaining
        }
        sleep_ms(wait_ms)
        continue attempt + 1
      }
    } noraise {
      _ => return
    }
  }
}

///|
pub async fn[T] slow(run : async () -> T, timeout_ms? : Int) -> T {
  let limit_ms = resolve_slow_timeout_ms(timeout_ms)
  timeout(ms=limit_ms, run)
}

///|
pub fn[T] step(name : String, run : () -> T) -> T {
  consume(name)
  run()
}

///|
pub async fn[T] step_async(name : String, run : async () -> T) -> T {
  consume(name)
  run()
}

///|
pub fn skip(run : () -> Unit) -> Unit {
  consume(run)
}

///|
pub fn skip_if(condition~ : Bool, run : () -> Unit) -> Unit {
  if !condition {
    run()
  }
}

///|
pub fn skip_async(run : async () -> Unit) -> Unit {
  consume(run)
}

///|
pub async fn skip_if_async(condition~ : Bool, run : async () -> Unit) -> Unit {
  if !condition {
    run()
  }
}

///|
#callsite(autofill(loc))
pub fn fail(
  run : () -> Unit raise,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  try run() catch {
    _ => ()
  } noraise {
    _ => {
      let message = match msg {
        Some(value) => value
        None => "expected block to fail"
      }
      assert_eq(true, false, msg=message, loc~)
    }
  }
}

///|
#callsite(autofill(loc))
pub fn fixme(
  run : () -> Unit raise,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  fail(run, msg?, loc~)
}

///|
#callsite(autofill(loc))
pub async fn fail_async(
  run : async () -> Unit,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  try run() catch {
    _ => ()
  } noraise {
    _ => {
      let message = match msg {
        Some(value) => value
        None => "expected block to fail"
      }
      assert_eq(true, false, msg=message, loc~)
    }
  }
}

///|
#callsite(autofill(loc))
pub async fn fixme_async(
  run : async () -> Unit,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  fail_async(run, msg?, loc~)
}

///|
pub fn in_shard(
  item_index~ : Int,
  item_total~ : Int,
  shard_index? : Int,
  shard_total? : Int,
) -> Bool {
  if item_total <= 0 {
    return false
  }
  if item_index < 0 || item_index >= item_total {
    return false
  }
  let total = resolve_shard_total(shard_total)
  let index = resolve_shard_index(shard_index, total)
  let start = (index - 1) * item_total / total
  let end = index * item_total / total
  item_index >= start && item_index < end
}

///|
pub fn shard(
  item_index~ : Int,
  item_total~ : Int,
  shard_index? : Int,
  shard_total? : Int,
  run : () -> Unit,
) -> Unit {
  if in_shard(item_index~, item_total~, shard_index?, shard_total?) {
    run()
  }
}

///|
pub async fn shard_async(
  item_index~ : Int,
  item_total~ : Int,
  shard_index? : Int,
  shard_total? : Int,
  run : async () -> Unit,
) -> Unit {
  if in_shard(item_index~, item_total~, shard_index?, shard_total?) {
    run()
  }
}
