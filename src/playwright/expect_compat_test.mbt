///|
struct DisplayValue {
  value : Int
} derive(Eq)

///|
impl Show for DisplayValue with fn output(self, logger) {
  logger.write_string("value=\{self.value}")
}

///|
test "equality matchers retain Eq and Show compatibility without Debug" {
  let value = DisplayValue::{ value: 7, }
  @playwright.expect(value).to_be(DisplayValue::{ value: 7, })
  @playwright.expect(value).to_equal(DisplayValue::{ value: 7, })
  let failed = try {
    @playwright.expect(value).to_equal(DisplayValue::{ value: 8, })
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}
