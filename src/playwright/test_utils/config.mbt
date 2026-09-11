///|
pub struct TestConfig {
  retry_times : Int
  timeout_ms : Int
  expect_timeout_ms : Int
  expect_interval_ms : Int
  slow_timeout_ms : Int
  shard_index : Int
  shard_total : Int
}

///|
fn positive_or(value : Int, fallback : Int) -> Int {
  if value <= 0 {
    fallback
  } else {
    value
  }
}

///|
fn clamp_retry_times(value : Int) -> Int {
  if value <= 1 {
    1
  } else {
    value
  }
}

///|
fn normalize_shard_total(shard_total : Int) -> Int {
  if shard_total <= 1 {
    1
  } else {
    shard_total
  }
}

///|
fn normalize_shard_index(shard_index : Int, shard_total : Int) -> Int {
  if shard_index <= 1 {
    1
  } else if shard_index > shard_total {
    shard_total
  } else {
    shard_index
  }
}

///|
fn normalize_test_config(config : TestConfig) -> TestConfig {
  let total = normalize_shard_total(config.shard_total)
  {
    retry_times: clamp_retry_times(config.retry_times),
    timeout_ms: positive_or(config.timeout_ms, 1),
    expect_timeout_ms: positive_or(config.expect_timeout_ms, 1),
    expect_interval_ms: positive_or(config.expect_interval_ms, 1),
    slow_timeout_ms: positive_or(config.slow_timeout_ms, 1),
    shard_index: normalize_shard_index(config.shard_index, total),
    shard_total: total,
  }
}

///|
pub fn default_test_config() -> TestConfig {
  {
    retry_times: 1,
    timeout_ms: 5_000,
    expect_timeout_ms: 5_000,
    expect_interval_ms: 50,
    slow_timeout_ms: 30_000,
    shard_index: 1,
    shard_total: 1,
  }
}

///|
let test_config_ref : Ref[TestConfig] = { val: default_test_config(), }

///|
pub fn current_test_config() -> TestConfig {
  test_config_ref.val
}

///|
pub fn set_test_config(config : TestConfig) -> Unit {
  test_config_ref.val = normalize_test_config(config)
}

///|
pub fn reset_test_config() -> Unit {
  test_config_ref.val = default_test_config()
}

///|
pub fn configure_test(
  retry_times? : Int,
  timeout_ms? : Int,
  expect_timeout_ms? : Int,
  expect_interval_ms? : Int,
  slow_timeout_ms? : Int,
  shard_index? : Int,
  shard_total? : Int,
) -> Unit {
  let base = current_test_config()
  let merged = {
    retry_times: match retry_times {
      Some(value) => value
      None => base.retry_times
    },
    timeout_ms: match timeout_ms {
      Some(value) => value
      None => base.timeout_ms
    },
    expect_timeout_ms: match expect_timeout_ms {
      Some(value) => value
      None => base.expect_timeout_ms
    },
    expect_interval_ms: match expect_interval_ms {
      Some(value) => value
      None => base.expect_interval_ms
    },
    slow_timeout_ms: match slow_timeout_ms {
      Some(value) => value
      None => base.slow_timeout_ms
    },
    shard_index: match shard_index {
      Some(value) => value
      None => base.shard_index
    },
    shard_total: match shard_total {
      Some(value) => value
      None => base.shard_total
    },
  }
  set_test_config(merged)
}

///|
pub fn[T] with_test_config(config : TestConfig, run : () -> T raise) -> T raise {
  let previous = current_test_config()
  set_test_config(config)
  defer set_test_config(previous)
  run()
}

///|
pub async fn[T] with_test_config_async(
  config : TestConfig,
  run : async () -> T,
) -> T {
  let previous = current_test_config()
  set_test_config(config)
  defer set_test_config(previous)
  run()
}
