///|
pub struct Expect[T] {
  actual : T
}

///|
pub fn[T] expect(actual : T) -> Expect[T] {
  { actual, }
}

///|
#callsite(autofill(loc))
pub fn[T : Eq + Show] Expect::to_be(
  self : Expect[T],
  expected : T,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  if self.actual != expected {
    let message = msg.unwrap_or("expected \{self.actual} to equal \{expected}")
    assert_true(false, msg=message, loc~)
  }
}

///|
#callsite(autofill(loc))
pub fn[T : Eq + Show] Expect::to_equal(
  self : Expect[T],
  expected : T,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  self.to_be(expected, msg?, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_match(
  self : Expect[String],
  pattern : String,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let ok = regex_match(self.actual, pattern)
  if ok {
    return ()
  }
  let message = match msg {
    Some(m) => m
    None => "expected \"" + self.actual + "\" to match /" + pattern + "/"
  }
  assert_eq(ok, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_be_truthy(
  self : Expect[Bool],
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let message = match msg {
    Some(m) => m
    None => "expected value to be truthy"
  }
  assert_eq(self.actual, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_be_falsy(
  self : Expect[Bool],
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let message = match msg {
    Some(m) => m
    None => "expected value to be falsy"
  }
  assert_eq(self.actual, false, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_contain(
  self : Expect[String],
  expected : String,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let ok = self.actual.contains(expected)
  if ok {
    return ()
  }
  let message = match msg {
    Some(m) => m
    None => "expected \"" + self.actual + "\" to contain \"" + expected + "\""
  }
  assert_eq(ok, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T : Eq + Show] Expect::to_contain_item(
  self : Expect[Array[T]],
  expected : T,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let mut ok = false
  for item in self.actual {
    if item == expected {
      ok = true
      break
    }
  }
  if ok {
    return ()
  }
  let message = match msg {
    Some(m) => m
    None => "expected array to contain " + Show::to_string(expected)
  }
  assert_eq(ok, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_have_length(
  self : Expect[String],
  expected : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let actual = self.actual.length()
  let message = match msg {
    Some(m) => m
    None =>
      "expected length " +
      expected.to_string() +
      " but was " +
      actual.to_string()
  }
  assert_eq(actual, expected, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T] Expect::to_have_length_items(
  self : Expect[Array[T]],
  expected : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let actual = self.actual.length()
  let message = match msg {
    Some(m) => m
    None =>
      "expected length " +
      expected.to_string() +
      " but was " +
      actual.to_string()
  }
  assert_eq(actual, expected, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_be_greater_than(
  self : Expect[Int],
  expected : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let ok = self.actual > expected
  if ok {
    return ()
  }
  let message = match msg {
    Some(m) => m
    None =>
      "expected " +
      self.actual.to_string() +
      " to be greater than " +
      expected.to_string()
  }
  assert_eq(ok, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_be_less_than(
  self : Expect[Int],
  expected : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let ok = self.actual < expected
  if ok {
    return ()
  }
  let message = match msg {
    Some(m) => m
    None =>
      "expected " +
      self.actual.to_string() +
      " to be less than " +
      expected.to_string()
  }
  assert_eq(ok, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub fn Expect::to_be_close_to(
  self : Expect[Double],
  expected : Double,
  precision? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit raise {
  let digits = match precision {
    Some(value) => if value < 0 { 0 } else { value }
    None => 2
  }
  let mut tolerance = 1.0
  for i = 0 {
    if i >= digits {
      break
    }
    tolerance = tolerance / 10.0
    continue i + 1
  }
  let diff = if self.actual > expected {
    self.actual - expected
  } else {
    expected - self.actual
  }
  let ok = diff <= tolerance / 2.0
  if ok {
    return ()
  }
  let message = match msg {
    Some(m) => m
    None =>
      "expected " +
      self.actual.to_string() +
      " to be close to " +
      expected.to_string()
  }
  assert_eq(ok, true, msg=message, loc~)
}

///|
priv enum TextMatchKind {
  Equal
  Contain
}

///|
fn normalize_text(text : String) -> String {
  let chars = text.to_array()
  let out : Array[Char] = []
  let in_space : Ref[Bool] = { val: false, }
  for ch in chars {
    if ch.is_whitespace() {
      if out.length() == 0 {
        in_space.val = true
        continue
      }
      if !in_space.val {
        out.push(' ')
        in_space.val = true
      }
      continue
    }
    out.push(ch)
    in_space.val = false
  }
  if out.length() > 0 && out[out.length() - 1] == ' ' {
    let _ = out.pop()
  }
  String::from_array(out)
}

///|
fn normalize_optional_text(value : String?) -> String {
  match value {
    Some(text) => if text == "null" || text == "undefined" { "" } else { text }
    None => ""
  }
}

///|
fn is_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn is_alpha(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

///|
fn parse_length(text : String) -> (Double, String)? {
  let chars = text.to_array()
  let mut index = 0
  while index < chars.length() && chars[index].is_whitespace() {
    index = index + 1
  }
  let mut sign = 1.0
  if index < chars.length() {
    if chars[index] == '-' {
      sign = -1.0
      index = index + 1
    } else if chars[index] == '+' {
      index = index + 1
    }
  }
  let mut int_part = 0
  let mut has_digit = false
  while index < chars.length() && is_digit(chars[index]) {
    int_part = int_part * 10 + (chars[index].to_int() - '0'.to_int())
    has_digit = true
    index = index + 1
  }
  let mut frac_part = 0
  let mut frac_div = 1.0
  if index < chars.length() && chars[index] == '.' {
    index = index + 1
    while index < chars.length() && is_digit(chars[index]) {
      frac_part = frac_part * 10 + (chars[index].to_int() - '0'.to_int())
      frac_div = frac_div * 10.0
      has_digit = true
      index = index + 1
    }
  }
  if !has_digit {
    return None
  }
  let unit_sb = StringBuilder()
  while index < chars.length() {
    let ch = chars[index]
    if is_alpha(ch) || ch == '%' {
      unit_sb.write_char(ch)
      index = index + 1
      continue
    }
    if ch.is_whitespace() {
      break
    }
    break
  }
  let value = (int_part.to_double() + frac_part.to_double() / frac_div) * sign
  let unit = unit_sb.to_string().to_lower()
  Some((value, unit))
}

///|
fn normalize_text_regex_pattern(pattern : String) -> String {
  if pattern.length() >= 2 && pattern.has_prefix("/") && pattern.has_suffix("/") {
    pattern[1:pattern.length() - 1].to_owned()
  } else {
    pattern
  }
}

///|
fn is_regex_pattern(text : String) -> Bool {
  text.length() >= 2 && text.has_prefix("/") && text.has_suffix("/")
}

///|
fn class_tokens(text : String) -> Array[String] {
  let norm = normalize_text(text)
  if norm.length() == 0 {
    return []
  }
  let out : Array[String] = []
  let mut sb = StringBuilder()
  let mut has_token = false
  for ch in norm {
    if ch == ' ' {
      if has_token {
        out.push(sb.to_string())
        sb = StringBuilder()
        has_token = false
      }
    } else {
      sb.write_char(ch)
      has_token = true
    }
  }
  if has_token {
    out.push(sb.to_string())
  }
  out
}

///|
fn normalize_class_tokens(tokens : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for token in tokens {
    let parts = class_tokens(token)
    for part in parts {
      out.push(part)
    }
  }
  out
}

///|
fn class_tokens_contains_all(
  actual_tokens : Array[String],
  expected_tokens : Array[String],
) -> Bool {
  let mut ok = true
  for expected in expected_tokens {
    let mut found = false
    for actual in actual_tokens {
      if actual == expected {
        found = true
        break
      }
    }
    if !found {
      ok = false
      break
    }
  }
  ok
}

///|
fn join_list(items : Array[String]) -> String {
  let sb = StringBuilder()
  let mut first = true
  for item in items {
    if !first {
      sb.write_view(", ")
    }
    sb.write_view(item)
    first = false
  }
  sb.to_string()
}

///|
fn resolve_text_match_mode(
  kind : TextMatchKind,
  match_mode : String?,
) -> String {
  match match_mode {
    Some(mode) => {
      let lower = mode.to_lower()
      if lower == "regex" || lower == "re" {
        "regex"
      } else if lower == "contains" ||
        lower == "include" ||
        lower == "substring" {
        "contains"
      } else {
        "exact"
      }
    }
    None =>
      match kind {
        TextMatchKind::Equal => "exact"
        TextMatchKind::Contain => "contains"
      }
  }
}

///|
fn class_matches(
  actual : String,
  expected : String,
  match_mode : String,
  normalize : Bool,
) -> Bool {
  let actual_text = if normalize { normalize_text(actual) } else { actual }
  let expected_text = if normalize {
    normalize_text(expected)
  } else {
    expected
  }
  match match_mode {
    "regex" =>
      regex_match(actual_text, normalize_text_regex_pattern(expected_text))
    "contains" =>
      if expected_text.contains(" ") {
        actual_text.contains(expected_text)
      } else {
        let tokens = class_tokens(actual_text)
        let mut ok = false
        for token in tokens {
          if token == expected_text {
            ok = true
            break
          }
        }
        ok
      }
    _ => actual_text == expected_text
  }
}

///|
fn class_expected_matches(
  actual : String,
  expected : String,
  match_mode : String,
  normalize : Bool,
  expected_tokens : Array[String],
) -> Bool {
  let use_token_mode = match_mode != "regex" &&
    (match_mode == "tokens" || expected_tokens.length() > 0)
  if use_token_mode {
    let actual_text = if normalize { normalize_text(actual) } else { actual }
    let actual_list = class_tokens(actual_text)
    let expected_list = if expected_tokens.length() > 0 {
      expected_tokens
    } else {
      class_tokens(if normalize { normalize_text(expected) } else { expected })
    }
    let ok_all = class_tokens_contains_all(actual_list, expected_list)
    if match_mode == "exact" {
      ok_all && actual_list.length() == expected_list.length()
    } else {
      ok_all
    }
  } else {
    class_matches(actual, expected, match_mode, normalize)
  }
}

///|
fn resolve_class_mode_for_expected(
  expected : String,
  base_mode : String,
  tokens : Array[String],
) -> String {
  if base_mode == "tokens" || tokens.length() > 0 {
    "tokens"
  } else if base_mode == "regex" {
    "regex"
  } else if is_regex_pattern(expected) {
    "regex"
  } else {
    base_mode
  }
}

///|
fn length_to_px(
  value : Double,
  unit : String,
  root_font : Double,
  em_size : Double,
  percent_base : Double?,
  viewport_width : Double?,
  viewport_height : Double?,
) -> Double? {
  match unit {
    "" => Some(value)
    "px" => Some(value)
    "rem" => Some(value * root_font)
    "em" => Some(value * em_size)
    "vw" =>
      match viewport_width {
        Some(base) => Some(value * base / 100.0)
        None => None
      }
    "vh" =>
      match viewport_height {
        Some(base) => Some(value * base / 100.0)
        None => None
      }
    "%" =>
      match percent_base {
        Some(base) => Some(value * base / 100.0)
        None => None
      }
    _ => None
  }
}

///|
fn infer_percent_base(
  name : String,
  viewport_width : Double?,
  viewport_height : Double?,
) -> Double? {
  let lower = name.to_lower()
  if lower.contains("width") ||
    lower.contains("left") ||
    lower.contains("right") {
    viewport_width
  } else if lower.contains("height") ||
    lower.contains("top") ||
    lower.contains("bottom") {
    viewport_height
  } else {
    None
  }
}

///|
fn numeric_matches(
  actual : String,
  expected : String,
  tolerance : Double,
  relative : Bool,
  root_font : Double,
  em_size : Double,
  percent_base : Double?,
  viewport_width : Double?,
  viewport_height : Double?,
) -> Bool {
  match (parse_length(expected), parse_length(actual)) {
    (Some((exp_value, exp_unit)), Some((act_value, act_unit))) => {
      let exp_px = length_to_px(
        exp_value, exp_unit, root_font, em_size, percent_base, viewport_width, viewport_height,
      )
      let act_px = length_to_px(
        act_value, act_unit, root_font, em_size, percent_base, viewport_width, viewport_height,
      )
      let (lhs, rhs) = match (exp_px, act_px) {
        (Some(lhs), Some(rhs)) => (lhs, rhs)
        _ =>
          if exp_unit == act_unit {
            (exp_value, act_value)
          } else {
            return false
          }
      }
      let diff = if rhs > lhs { rhs - lhs } else { lhs - rhs }
      if relative {
        let base = if lhs < 0.0 { -lhs } else { lhs }
        let rel_tol = if tolerance <= 0.0 { 0.01 } else { tolerance }
        diff <= base * rel_tol
      } else {
        diff <= tolerance
      }
    }
    _ => false
  }
}

///|
fn text_matches(
  actual : String,
  expected : String,
  match_mode : String,
  normalize : Bool,
) -> Bool {
  let actual_text = if normalize { normalize_text(actual) } else { actual }
  let expected_text = if normalize {
    normalize_text(expected)
  } else {
    expected
  }
  match match_mode {
    "regex" =>
      regex_match(actual_text, normalize_text_regex_pattern(expected_text))
    "contains" => actual_text.contains(expected_text)
    _ => actual_text == expected_text
  }
}

///|
async fn[T] wait_for_match(
  timeout_ms : Int,
  poll : async () -> T,
  matches : (T) -> Bool,
  initial : T,
) -> (Bool, T) {
  let start = @async.now()
  let last : Ref[T] = { val: initial, }
  let matched = for attempt = 0 {
    let value = poll()
    last.val = value
    if matches(value) {
      break true
    }
    if timeout_ms <= 0 {
      break false
    }
    let elapsed = @async.now() - start
    if elapsed >= timeout_ms.to_int64() {
      break false
    }
    let remaining = timeout_ms - elapsed.to_int()
    let base = 10
    let cap = 200
    let step = if attempt > 6 { 6 } else { attempt }
    let delay = base * (1 << step)
    let wait = if delay > cap { cap } else { delay }
    let wait_ms = if wait > remaining { remaining } else { wait }
    sleep_ms(wait_ms)
    continue attempt + 1
  }
  (matched, last.val)
}

///|
async fn wait_for_text_match(
  locator : Locator,
  expected : String,
  kind : TextMatchKind,
  timeout_ms : Int,
  match_mode : String?,
  normalize : Bool?,
) -> (Bool, String) {
  let normalize_value = match normalize {
    Some(value) => value
    None => true
  }
  let mode = resolve_text_match_mode(kind, match_mode)
  let (matched, last) = wait_for_match(
    timeout_ms,
    async fn() { locator.inner_text() },
    fn(text : String) { text_matches(text, expected, mode, normalize_value) },
    "",
  )
  (matched, last)
}

///|
fn locator_with_index(locator : Locator, index : Int) -> Locator {
  let state = locator.state.val
  let next : LocatorState = {
    page: state.page,
    selector: state.selector,
    index: Some(index),
    has_text: state.has_text,
    has_text_exact: state.has_text_exact,
    has_not_text: state.has_not_text,
    label_text: state.label_text,
    label_text_exact: state.label_text_exact,
    label_scope_selector: state.label_scope_selector,
  }
  { state: { val: next, }, }
}

///|
async fn locator_exists(locator : Locator) -> Bool {
  let expr = locator.element_expression() + " != null"
  match locator.eval_bool(expr) {
    Some(value) => value
    None => false
  }
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_text(
  self : Expect[Locator],
  expected : String,
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  normalize? : Bool,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_text_match(
    self.actual,
    expected,
    TextMatchKind::Equal,
    timeout_ms,
    match_mode,
    normalize,
  )
  if matched {
    return ()
  }
  let message = match msg {
    Some(value) => value
    None =>
      "expected text to be \"" + expected + "\" but was \"" + actual + "\""
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_contain_text(
  self : Expect[Locator],
  expected : String,
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  normalize? : Bool,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_text_match(
    self.actual,
    expected,
    TextMatchKind::Contain,
    timeout_ms,
    match_mode,
    normalize,
  )
  if matched {
    return ()
  }
  let message = match msg {
    Some(value) => value
    None =>
      "expected text to contain \"" + expected + "\" but was \"" + actual + "\""
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_class(
  self : Expect[Locator],
  expected : String,
  expected_tokens? : Array[String],
  expected_list? : Array[String],
  expected_list_tokens? : Array[Array[String]],
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  normalize? : Bool,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let normalize_value = match normalize {
    Some(value) => value
    None => true
  }
  let token_list = match expected_tokens {
    Some(tokens) => normalize_class_tokens(tokens)
    None => []
  }
  let expected_list_value = match expected_list {
    Some(list) => list
    None => []
  }
  let expected_list_tokens_value = match expected_list_tokens {
    Some(list) => list
    None => []
  }
  let mode = match match_mode {
    Some(value) => {
      let lower = value.to_lower()
      if lower == "tokens" ||
        lower == "token" ||
        lower == "classes" ||
        lower == "classlist" {
        "tokens"
      } else {
        resolve_text_match_mode(TextMatchKind::Equal, match_mode)
      }
    }
    None => if token_list.length() > 0 { "tokens" } else { "exact" }
  }
  if expected_list_value.length() > 0 {
    let initial : (Array[String], Bool, Bool) = ([], false, false)
    let (matched, result) = wait_for_match(
      timeout_ms,
      async fn() {
        let actuals : Array[String] = []
        let mut all_present = true
        let mut index = 0
        while index < expected_list_value.length() {
          let loc = locator_with_index(self.actual, index)
          let exists = locator_exists(loc)
          if !exists {
            all_present = false
            actuals.push("<missing>")
          } else {
            let value = loc.get_attribute("class")
            actuals.push(normalize_optional_text(value))
          }
          index = index + 1
        }
        let extra_index = expected_list_value.length()
        let extra_exists = if extra_index == 0 {
          locator_exists(locator_with_index(self.actual, 0))
        } else {
          locator_exists(locator_with_index(self.actual, extra_index))
        }
        (actuals, all_present, extra_exists)
      },
      fn(result : (Array[String], Bool, Bool)) {
        let (actuals, all_present, extra_exists) = result
        if !all_present {
          return false
        }
        if extra_exists {
          return false
        }
        if actuals.length() != expected_list_value.length() {
          return false
        }
        let mut ok = true
        let mut index = 0
        while index < expected_list_value.length() {
          let actual_value = actuals[index]
          let expected_value = expected_list_value[index]
          let item_tokens = if expected_list_tokens_value.length() > 0 &&
            index < expected_list_tokens_value.length() {
            normalize_class_tokens(expected_list_tokens_value[index])
          } else {
            token_list
          }
          let item_mode = resolve_class_mode_for_expected(
            expected_value, mode, item_tokens,
          )
          if !class_expected_matches(
              actual_value, expected_value, item_mode, normalize_value, item_tokens,
            ) {
            ok = false
            break
          }
          index = index + 1
        }
        ok
      },
      initial,
    )
    if matched {
      return ()
    }
    let (actuals, _, extra_exists) = result
    let extra_note = if extra_exists { " (extra elements)" } else { "" }
    let message = match msg {
      Some(value) => value
      None =>
        "expected class list to match [" +
        join_list(expected_list_value) +
        "] but was [" +
        join_list(actuals) +
        "]" +
        extra_note
    }
    assert_eq(matched, true, msg=message, loc~)
  } else {
    let (matched, actual) = wait_for_match(
      timeout_ms,
      async fn() {
        let value = self.actual.get_attribute("class")
        normalize_optional_text(value)
      },
      fn(value : String) {
        class_expected_matches(
          value, expected, mode, normalize_value, token_list,
        )
      },
      "",
    )
    if matched {
      return ()
    }
    let message = match msg {
      Some(value) => value
      None =>
        "expected class to match \"" +
        expected +
        "\" but was \"" +
        actual +
        "\""
    }
    assert_eq(matched, true, msg=message, loc~)
  }
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_css(
  self : Expect[Locator],
  name : String,
  expected : String,
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  normalize? : Bool,
  numeric? : Bool,
  tolerance? : Double,
  relative? : Bool,
  root_font_size? : Double,
  em_size? : Double,
  percent_base? : Double,
  viewport_width? : Double,
  viewport_height? : Double,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let normalize_value = match normalize {
    Some(value) => value
    None => true
  }
  let numeric_value = match numeric {
    Some(true) => true
    _ => false
  }
  let relative_value = match relative {
    Some(true) => true
    _ => false
  }
  let tolerance_value = match tolerance {
    Some(value) => if value < 0.0 { 0.0 } else { value }
    None => 0.0
  }
  let root_font_value = match root_font_size {
    Some(value) => if value <= 0.0 { 16.0 } else { value }
    None => 16.0
  }
  let em_value = match em_size {
    Some(value) => if value <= 0.0 { root_font_value } else { value }
    None => root_font_value
  }
  let viewport_width_value = match viewport_width {
    Some(value) => if value <= 0.0 { None } else { Some(value) }
    None => None
  }
  let viewport_height_value = match viewport_height {
    Some(value) => if value <= 0.0 { None } else { Some(value) }
    None => None
  }
  let percent_base_value = match percent_base {
    Some(value) => if value <= 0.0 { None } else { Some(value) }
    None =>
      infer_percent_base(name, viewport_width_value, viewport_height_value)
  }
  let mode = resolve_text_match_mode(TextMatchKind::Equal, match_mode)
  let expr = "(function(){ const el = " +
    self.actual.element_expression() +
    "; if (!el) return ''; const doc = el.ownerDocument || document; const view = doc.defaultView || window; if (!view || !view.getComputedStyle) return ''; const style = view.getComputedStyle(el); if (!style) return ''; const value = style.getPropertyValue(" +
    js_string_literal(name) +
    "); return value == null ? '' : String(value); })()"
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() {
      let value = self.actual.eval_string(expr)
      normalize_optional_text(value)
    },
    fn(value : String) {
      if numeric_value {
        let value_text = if normalize_value {
          normalize_text(value)
        } else {
          value
        }
        numeric_matches(
          value_text, expected, tolerance_value, relative_value, root_font_value,
          em_value, percent_base_value, viewport_width_value, viewport_height_value,
        )
      } else {
        text_matches(value, expected, mode, normalize_value)
      }
    },
    "",
  )
  if matched {
    return ()
  }
  let message = match msg {
    Some(value) => value
    None =>
      "expected css \"" +
      name +
      "\" to match \"" +
      expected +
      "\" but was \"" +
      actual +
      "\""
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_be_focused(
  self : Expect[Locator],
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let expr = "(function(){ const el = " +
    self.actual.element_expression() +
    "; if (!el) return false; const doc = el.ownerDocument || document; const active = doc.activeElement; return el === active; })()"
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() {
      match self.actual.eval_bool(expr) {
        Some(value) => value
        None => false
      }
    },
    fn(value : Bool) { value },
    false,
  )
  if matched {
    return ()
  }
  let state = if actual { "focused" } else { "not focused" }
  let message = match msg {
    Some(value) => value
    None => "expected locator to be focused but was " + state
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_be_visible(
  self : Expect[Locator],
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.is_visible() },
    fn(value : Bool) { value },
    false,
  )
  if matched {
    return ()
  }
  let state = if actual { "visible" } else { "hidden" }
  let message = match msg {
    Some(value) => value
    None => "expected locator to be visible but was " + state
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_be_hidden(
  self : Expect[Locator],
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.is_hidden() },
    fn(value : Bool) { value },
    false,
  )
  if matched {
    return ()
  }
  let state = if actual { "hidden" } else { "visible" }
  let message = match msg {
    Some(value) => value
    None => "expected locator to be hidden but was " + state
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_be_enabled(
  self : Expect[Locator],
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.is_enabled() },
    fn(value : Bool) { value },
    false,
  )
  if matched {
    return ()
  }
  let state = if actual { "enabled" } else { "disabled" }
  let message = match msg {
    Some(value) => value
    None => "expected locator to be enabled but was " + state
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_be_disabled(
  self : Expect[Locator],
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.is_disabled() },
    fn(value : Bool) { value },
    false,
  )
  if matched {
    return ()
  }
  let state = if actual { "disabled" } else { "enabled" }
  let message = match msg {
    Some(value) => value
    None => "expected locator to be disabled but was " + state
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_be_checked(
  self : Expect[Locator],
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.is_checked() },
    fn(value : Bool) { value },
    false,
  )
  if matched {
    return ()
  }
  let state = if actual { "checked" } else { "unchecked" }
  let message = match msg {
    Some(value) => value
    None => "expected locator to be checked but was " + state
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_be_editable(
  self : Expect[Locator],
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.is_editable() },
    fn(value : Bool) { value },
    false,
  )
  if matched {
    return ()
  }
  let state = if actual { "editable" } else { "read-only" }
  let message = match msg {
    Some(value) => value
    None => "expected locator to be editable but was " + state
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_value(
  self : Expect[Locator],
  expected : String,
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  normalize? : Bool,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let normalize_value = match normalize {
    Some(value) => value
    None => false
  }
  let mode = resolve_text_match_mode(TextMatchKind::Equal, match_mode)
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.input_value() },
    fn(value : String) { text_matches(value, expected, mode, normalize_value) },
    "",
  )
  if matched {
    return ()
  }
  let message = match msg {
    Some(value) => value
    None =>
      "expected value to be \"" + expected + "\" but was \"" + actual + "\""
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_attribute(
  self : Expect[Locator],
  name : String,
  expected? : String,
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  normalize? : Bool,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let normalize_value = match normalize {
    Some(value) => value
    None => false
  }
  let mode = resolve_text_match_mode(TextMatchKind::Equal, match_mode)
  let initial : String? = None
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.get_attribute(name) },
    fn(value : String?) {
      match expected {
        Some(exp) =>
          match value {
            Some(actual_value) =>
              text_matches(actual_value, exp, mode, normalize_value)
            None => false
          }
        None =>
          match value {
            Some(_) => true
            None => false
          }
      }
    },
    initial,
  )
  if matched {
    return ()
  }
  let actual_text = match actual {
    Some(value) => value
    None => "null"
  }
  let message = match msg {
    Some(value) => value
    None =>
      match expected {
        Some(exp) =>
          "expected attribute \"" +
          name +
          "\" to match \"" +
          exp +
          "\" but was \"" +
          actual_text +
          "\""
        None =>
          "expected attribute \"" +
          name +
          "\" to be present but was \"" +
          actual_text +
          "\""
      }
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_count(
  self : Expect[Locator],
  expected : Int,
  timeout? : Int,
  msg? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.count() },
    fn(value : Int) { value == expected },
    0,
  )
  if matched {
    return ()
  }
  let message = match msg {
    Some(value) => value
    None =>
      "expected count " +
      expected.to_string() +
      " but was " +
      actual.to_string()
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_url(
  self : Expect[Page],
  expected : String,
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let mode = resolve_match_mode(expected, match_mode)
  let initial = self.actual.url()
  let (matched, actual) = wait_for_match(
    timeout_ms,
    fn() { self.actual.url() },
    fn(value : String) { url_matches(value, expected, mode) },
    initial,
  )
  if matched {
    return ()
  }
  let message = match msg {
    Some(value) => value
    None =>
      "expected url to match \"" + expected + "\" but was \"" + actual + "\""
  }
  assert_eq(matched, true, msg=message, loc~)
}

///|
#callsite(autofill(loc))
pub async fn Expect::to_have_title(
  self : Expect[Page],
  expected : String,
  timeout? : Int,
  msg? : String,
  match_mode? : String,
  normalize? : Bool,
  loc~ : SourceLoc,
) -> Unit {
  let timeout_ms = match timeout {
    Some(value) => value
    None => 5_000
  }
  let normalize_value = match normalize {
    Some(value) => value
    None => true
  }
  let mode = resolve_text_match_mode(TextMatchKind::Equal, match_mode)
  let (matched, actual) = wait_for_match(
    timeout_ms,
    async fn() { self.actual.title() },
    fn(value : String) { text_matches(value, expected, mode, normalize_value) },
    "",
  )
  if matched {
    return ()
  }
  let message = match msg {
    Some(value) => value
    None =>
      "expected title to be \"" + expected + "\" but was \"" + actual + "\""
  }
  assert_eq(matched, true, msg=message, loc~)
}
