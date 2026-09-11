///|
test "evaluate distinguishes functions from immediately invoked expressions" {
  for
    source in [
      "() => document.title", "(a, b) => a + b", "async () => 1", "function() { return 1; }",
      "(() => 1)", "(function() { return 1; })", "value => value", "() => (() => 1)()",
    ] {
    assert_true(is_function_expression(source), msg=source)
  }
  for
    source in [
      "document.title", "(() => 1)()", "(function() { return 1; })()", "(1 + 2)",
      "[1, 2].map(value => value * 2)",
    ] {
    assert_false(is_function_expression(source), msg=source)
  }
}
