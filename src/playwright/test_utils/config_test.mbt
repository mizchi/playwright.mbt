///|
suberror ConfigFailure {
  ConfigFailure
}

///|
test "scoped config restores the previous config on success and failure" {
  let original = current_test_config()
  defer set_test_config(original)
  configure_test(retry_times=original.retry_times + 1)
  let scoped = current_test_config()
  set_test_config(original)
  let value = with_test_config(scoped, fn() {
    assert_eq(current_test_config().retry_times, scoped.retry_times)
    7
  })
  assert_eq(value, 7)
  assert_eq(current_test_config().retry_times, original.retry_times)
  try
    with_test_config(scoped, fn() -> Unit raise {
      assert_eq(current_test_config().retry_times, scoped.retry_times)
      raise ConfigFailure
    })
  catch {
    ConfigFailure => ()
    error => raise error
  } noraise {
    _ => assert_true(false, msg="callback failure must propagate")
  }
  assert_eq(current_test_config().retry_times, original.retry_times)
}

///|
async test "async scoped config restores the previous config on success and failure" {
  let original = current_test_config()
  defer set_test_config(original)
  configure_test(retry_times=original.retry_times + 1)
  let scoped = current_test_config()
  set_test_config(original)
  let value = with_test_config_async(scoped, async fn() {
    assert_eq(current_test_config().retry_times, scoped.retry_times)
    7
  })
  assert_eq(value, 7)
  assert_eq(current_test_config().retry_times, original.retry_times)
  try
    with_test_config_async(scoped, async fn() -> Unit {
      assert_eq(current_test_config().retry_times, scoped.retry_times)
      raise ConfigFailure
    })
  catch {
    ConfigFailure => ()
    error => raise error
  } noraise {
    _ => assert_true(false, msg="callback failure must propagate")
  }
  assert_eq(current_test_config().retry_times, original.retry_times)
}
