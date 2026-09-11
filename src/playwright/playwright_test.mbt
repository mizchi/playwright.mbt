///|
/// Playwright BiDi tests

///|
fn make_mock_transport(
  sent : Ref[Array[String]],
  recv_queue : Ref[Array[String]],
) -> @bidi.Transport {
  let connect = fn() -> Result[Unit, @bidi.TransportError] { Ok(()) }
  let send = fn(message : String) -> Result[Unit, @bidi.TransportError] {
    sent.val.push(message)
    Ok(())
  }
  let recv = fn() -> Result[String, @bidi.TransportError] {
    if recv_queue.val.length() == 0 {
      Ok("{\"id\":0,\"type\":\"success\",\"result\":{}}")
    } else {
      let head = recv_queue.val.remove(0)
      Ok(head)
    }
  }
  let close = fn() -> Result[Unit, @bidi.TransportError] { Ok(()) }
  @bidi.Transport::custom(
    @bidi.CustomTransport::new(connect, send, recv, close),
  )
}

///|
fn test_get_string_field(json : Json, key : String) -> String? {
  match json {
    Object(map) =>
      match map.get(key) {
        Some(String(s)) => Some(s)
        _ => None
      }
    _ => None
  }
}

///|
fn test_get_object_field(json : Json, key : String) -> Json? {
  match json {
    Object(map) =>
      match map.get(key) {
        Some(Object(obj)) => Some(Json::object(obj))
        _ => None
      }
    _ => None
  }
}

///|
fn test_get_array_field(json : Json, key : String) -> Array[Json]? {
  match json {
    Object(map) =>
      match map.get(key) {
        Some(Array(items)) => Some(items)
        _ => None
      }
    _ => None
  }
}

///|
async test "chromium connect and page flow" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"navigation\":\"nav-1\",\"url\":\"https://example.com\"}}",
      "{\"id\":5,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"Example\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  assert_true(browser.is_connected())
  let page = browser.new_page()
  let response = page.goto("https://example.com")
  match response {
    Some(resp) => inspect(resp.url(), content="https://example.com")
    None => assert_true(false)
  }
  let title = page.title()
  inspect(title, content="Example")
  let req0 = @json.parse(sent.val[0]) catch { _ => Json::null() }
  let params0 = test_get_object_field(req0, "params").unwrap()
  assert_true(test_get_object_field(params0, "capabilities") is Some(_))
  @debug.debug_inspect(
    test_get_string_field(req0, "method"),
    content="Some(\"session.new\")",
  )
  let req1 = @json.parse(sent.val[1]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req1, "method"),
    content="Some(\"session.subscribe\")",
  )
  let req2 = @json.parse(sent.val[2]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req2, "method"),
    content="Some(\"browsingContext.create\")",
  )
  let req3 = @json.parse(sent.val[3]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req3, "method"),
    content="Some(\"browsingContext.navigate\")",
  )
  let params2 = test_get_object_field(req3, "params").unwrap_or(
    Json::object({}),
  )
  @debug.debug_inspect(
    test_get_string_field(params2, "url"),
    content="Some(\"https://example.com\")",
  )
  let req4 = @json.parse(sent.val[4]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req4, "method"),
    content="Some(\"script.evaluate\")",
  )
  let params3 = test_get_object_field(req4, "params").unwrap_or(
    Json::object({}),
  )
  @debug.debug_inspect(
    test_get_string_field(params3, "expression"),
    content="Some(\"document.title\")",
  )
}

///|
async test "connect over websocket" {
  let browser = chromium().connect_over_websocket("ws://127.0.0.1:9")
  inspect(browser.is_connected(), content="true")
}

///|
test "browser type name" {
  inspect(chromium().name(), content="chromium")
  inspect(firefox().name(), content="firefox")
  inspect(webkit().name(), content="webkit")
}

///|
test "headers and bounding box codecs" {
  let headers = Headers::from_json(
    Json::object({
      "content-type": Json::string("text/html"),
      "x-number": Json::number(1.0),
      "x-flag": Json::boolean(true),
    }),
  )
  @debug.debug_inspect(
    headers.get("content-type"),
    content="Some(\"text/html\")",
  )
  @debug.debug_inspect(headers.get("x-flag"), content="Some(\"true\")")
  match headers.get("x-number") {
    Some(value) => assert_true(value == "1" || value == "1.0")
    None => assert_true(false)
  }
  let bbox_json = Json::object({
    "x": Json::number(1.0),
    "y": Json::number(2.0),
    "width": Json::number(3.0),
    "height": Json::number(4.0),
  })
  match BoundingBox::from_json(bbox_json) {
    Some(bbox) => {
      assert_eq(bbox.x, 1.0)
      assert_eq(bbox.y, 2.0)
      assert_eq(bbox.width, 3.0)
      assert_eq(bbox.height, 4.0)
    }
    None => assert_true(false)
  }
  let margin = Margin::new(top=Length::points(1.0), right=Length::css("2px"))
  let _ = margin.to_json()
  let clip = Clip::new(1.0, 2.0, 3.0, 4.0)
  let _ = clip.to_json()
}

///|
async test "locator bounding box" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"{\\\"x\\\":1,\\\"y\\\":2,\\\"width\\\":3,\\\"height\\\":4}\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  match page.locator("div").bounding_box() {
    Some(bbox) => {
      assert_eq(bbox.x, 1.0)
      assert_eq(bbox.y, 2.0)
      assert_eq(bbox.width, 3.0)
      assert_eq(bbox.height, 4.0)
    }
    None => assert_true(false)
  }
  let req = @json.parse(sent.val[3]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req, "method"),
    content="Some(\"script.evaluate\")",
  )
}

///|
async test "expect locator text matchers" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"  Hello   World  \"}}}",
      "{\"id\":5,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"Hello\\nWorld\"}}}",
      "{\"id\":6,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"Hello   World\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let locator = page.locator("div")
  expect(locator).to_have_text("Hello World")
  expect(locator).to_contain_text("Hello")
  expect(locator).to_have_text("/Hello\\s+World/", match_mode="regex")
  let req = @json.parse(sent.val[3]) catch { _ => Json::null() }
  let params = test_get_object_field(req, "params").unwrap_or(Json::object({}))
  match test_get_string_field(params, "expression") {
    Some(expr) => assert_true(expr.contains("innerText"))
    None => assert_true(false)
  }
  let req2 = @json.parse(sent.val[4]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req2, "method"),
    content="Some(\"script.evaluate\")",
  )
}

///|
async test "expect locator state and page matchers" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"navigation\":\"nav-1\",\"url\":\"https://example.com\"}}",
      "{\"id\":5,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":true}}}",
      "{\"id\":6,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":true}}}",
      "{\"id\":7,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":true}}}",
      "{\"id\":8,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"hello\"}}}",
      "{\"id\":9,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"xyz\"}}}",
      "{\"id\":10,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"My Title\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let _ = page.goto("https://example.com")
  let locator = page.locator("input")
  expect(locator).to_be_visible()
  expect(locator).to_be_enabled()
  expect(locator).to_be_checked()
  expect(locator).to_have_value("hello")
  expect(locator).to_have_attribute("data-id", expected="xyz")
  expect(locator).to_have_count(0)
  expect(page).to_have_url("example.com", match_mode="contains")
  expect(page).to_have_title("My Title")
}

///|
async test "expect locator class css and focused" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"btn-primary active\"}}}",
      "{\"id\":5,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"btn-primary active\"}}}",
      "{\"id\":6,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"btn-primary active\"}}}",
      "{\"id\":7,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"btn-primary active\"}}}",
      "{\"id\":8,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"btn-primary active\"}}}",
      "{\"id\":9,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":true}}}",
      "{\"id\":10,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"btn-primary active\"}}}",
      "{\"id\":11,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":true}}}",
      "{\"id\":12,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"btn-primary active\"}}}",
      "{\"id\":13,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":false}}}",
      "{\"id\":14,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"block\"}}}",
      "{\"id\":15,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"rgb(0, 0, 0)\"}}}",
      "{\"id\":16,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"100px\"}}}",
      "{\"id\":17,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"32px\"}}}",
      "{\"id\":18,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"100px\"}}}",
      "{\"id\":19,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"100px\"}}}",
      "{\"id\":20,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"101px\"}}}",
      "{\"id\":21,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":true}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let locator = page.locator("button")
  expect(locator).to_have_class("btn-primary active")
  expect(locator).to_have_class("btn-primary", match_mode="contains")
  expect(locator).to_have_class("/active$/", match_mode="regex")
  expect(locator).to_have_class("", expected_tokens=["btn-primary", "active"])
  expect(locator).to_have_class("btn-primary active", match_mode="tokens")
  expect(locator).to_have_class(
    "",
    expected_list=["/active$/", "btn-primary active"],
    expected_list_tokens=[[], ["btn-primary", "active"]],
  )
  expect(locator).to_have_css("display", "block")
  expect(locator).to_have_css("color", "rgb(0, 0, 0)")
  expect(locator).to_have_css("width", "100", numeric=true)
  expect(locator).to_have_css("height", "2rem", numeric=true)
  expect(locator).to_have_css(
    "margin-left",
    "50%",
    numeric=true,
    viewport_width=200.0,
  )
  expect(locator).to_have_css(
    "left",
    "50vw",
    numeric=true,
    viewport_width=200.0,
  )
  expect(locator).to_have_css(
    "top",
    "25vh",
    numeric=true,
    relative=true,
    tolerance=0.02,
    viewport_height=400.0,
  )
  expect(locator).to_be_focused()
}

///|
async test "handles and response body" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"ok\"}}}",
      "{\"id\":5,\"type\":\"success\",\"result\":{\"nodes\":[{\"sharedId\":\"node-1\"}]}}",
      "{\"id\":6,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"boolean\",\"value\":true}}}",
      "{\"id\":7,\"type\":\"success\",\"result\":{\"nodes\":[{\"sharedId\":\"node-1\"},{\"sharedId\":\"node-2\"}]}}",
      "{\"id\":8,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"arg-ok\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let handle = page.evaluate_handle("(() => 'ok')()")
  json_inspect(handle.json_value(), content=Json::string("ok"))
  let element = page.wait_for_selector("div")
  match element {
    Some(el) =>
      match el.json_value() {
        Null => assert_true(false)
        _ => assert_true(true)
      }
    None => assert_true(false)
  }
  match JSHandle::null().as_element() {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  try page.wait_for_selector("div", strict=true) catch {
    PlaywrightError::StrictModeViolation(..) => ()
    _ => assert_true(false)
  } noraise {
    _ => assert_true(false)
  }
  let eval_result = handle.evaluate(
    "(node, arg) => arg",
    arg=Json::string("arg-ok"),
  )
  json_inspect(eval_result, content=Json::string("arg-ok"))
  let req2 = @json.parse(sent.val[3]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req2, "method"),
    content="Some(\"script.evaluate\")",
  )
  let req3 = @json.parse(sent.val[4]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req3, "method"),
    content="Some(\"browsingContext.locateNodes\")",
  )
  let params3 = test_get_object_field(req3, "params").unwrap_or(
    Json::object({}),
  )
  let locator3 = test_get_object_field(params3, "locator").unwrap_or(
    Json::object({}),
  )
  @debug.debug_inspect(
    test_get_string_field(locator3, "type"),
    content="Some(\"css\")",
  )
  @debug.debug_inspect(
    test_get_string_field(locator3, "value"),
    content="Some(\"div\")",
  )
  let req4 = @json.parse(sent.val[5]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req4, "method"),
    content="Some(\"script.callFunction\")",
  )
  let params4 = test_get_object_field(req4, "params").unwrap_or(
    Json::object({}),
  )
  let args4 = test_get_array_field(params4, "arguments").unwrap_or([])
  assert_true(args4.length() == 1)
  let req5 = @json.parse(sent.val[6]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req5, "method"),
    content="Some(\"browsingContext.locateNodes\")",
  )
  let params5 = test_get_object_field(req5, "params").unwrap_or(
    Json::object({}),
  )
  let locator5 = test_get_object_field(params5, "locator").unwrap_or(
    Json::object({}),
  )
  @debug.debug_inspect(
    test_get_string_field(locator5, "type"),
    content="Some(\"css\")",
  )
  @debug.debug_inspect(
    test_get_string_field(locator5, "value"),
    content="Some(\"div\")",
  )
  let req6 = @json.parse(sent.val[7]) catch { _ => Json::null() }
  @debug.debug_inspect(
    test_get_string_field(req6, "method"),
    content="Some(\"script.callFunction\")",
  )
  let params6 = test_get_object_field(req6, "params").unwrap_or(
    Json::object({}),
  )
  let args6 = test_get_array_field(params6, "arguments").unwrap_or([])
  assert_true(args6.length() == 2)
  let text = ResponseBody::text("hello")
  match text.as_text() {
    Some(value) => assert_eq(value, "hello")
    None => assert_true(false)
  }
  let json_body = ResponseBody::json(
    Json::object({ "ok": Json::boolean(true) }),
  )
  match json_body.as_json() {
    Some(value) =>
      json_inspect(value, content=Json::object({ "ok": Json::boolean(true) }))
    None => assert_true(false)
  }
  let bytes_body = ResponseBody::bytes(b"hi")
  match bytes_body.as_bytes() {
    Some(value) => assert_eq(value.length(), 2)
    None => assert_true(false)
  }
}

///|
async test "get_by_text and wait_for_timeout" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"null\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let locator = page.get_by_text("Hello")
  locator.click()
  let start = @async.now()
  page.wait_for_timeout(10)
  let elapsed = @async.now() - start
  assert_true(elapsed.to_int() >= 5)
  let req2 = @json.parse(sent.val[3]) catch { _ => Json::null() }
  let params2 = test_get_object_field(req2, "params").unwrap_or(
    Json::object({}),
  )
  match test_get_string_field(params2, "expression") {
    Some(expr) => {
      assert_true(expr.contains("querySelectorAll"))
      assert_true(expr.contains("const txt = \"Hello\""))
    }
    None => assert_true(false)
  }
}

///|
async test "filter has_text and get_by_label" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"null\"}}}",
      "{\"id\":5,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"null\"}}}",
      "{\"id\":6,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"null\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let locator = page
    .locator("div")
    .filter(has_text="Hello", has_not_text="Skip")
  locator.click()
  page.get_by_label("Name").click()
  page.locator("section").get_by_label("Scoped").click()
  let req2 = @json.parse(sent.val[3]) catch { _ => Json::null() }
  let params2 = test_get_object_field(req2, "params").unwrap_or(
    Json::object({}),
  )
  match test_get_string_field(params2, "expression") {
    Some(expr) => {
      assert_true(expr.contains("querySelectorAll"))
      assert_true(expr.contains("const txt = \"Hello\""))
      assert_true(expr.contains("const notTxt = \"Skip\""))
    }
    None => assert_true(false)
  }
  let req3 = @json.parse(sent.val[4]) catch { _ => Json::null() }
  let params3 = test_get_object_field(req3, "params").unwrap_or(
    Json::object({}),
  )
  match test_get_string_field(params3, "expression") {
    Some(expr) => {
      assert_true(expr.contains("querySelectorAll(\"label\")"))
      assert_true(expr.contains("const txt = \"Name\""))
      assert_true(expr.contains("getAttribute('for')"))
      assert_true(expr.contains("aria-labelledby"))
      assert_true(expr.contains("aria-label"))
      assert_true(expr.contains("parts.join"))
      assert_true(expr.contains("label[for=\""))
      assert_true(expr.contains("labelledByText"))
      assert_true(expr.contains("accessibleName"))
      assert_true(expr.contains("innerText"))
      assert_true(expr.contains("compareDocumentPosition"))
      assert_true(expr.contains("is_visible"))
      assert_true(expr.contains("getClientRects"))
      assert_true(expr.contains("getBoundingClientRect"))
      assert_true(expr.contains("aria-hidden"))
      assert_true(expr.contains("labelDistance"))
      assert_true(expr.contains("domDistance"))
      assert_true(expr.contains("labelNodesFor"))
      assert_true(expr.contains("labelScore"))
      assert_true(expr.contains("return 1; } let parent"))
      assert_true(expr.contains("node.contains"))
      assert_true(
        expr.contains("visibility === 'collapse' && (cur.tagName === 'TABLE'"),
      )
      assert_true(expr.contains("replace(/\\s+/g"))
      assert_true(expr.contains("ids.indexOf"))
      assert_true(expr.contains("u00a0"))
      assert_true(expr.contains("u200B"))
      assert_true(expr.contains("parts.length > 0"))
    }
    None => assert_true(false)
  }
  let req4 = @json.parse(sent.val[5]) catch { _ => Json::null() }
  let params4 = test_get_object_field(req4, "params").unwrap_or(
    Json::object({}),
  )
  match test_get_string_field(params4, "expression") {
    Some(expr) => {
      assert_true(expr.contains("querySelectorAll(\"section label\")"))
      assert_true(expr.contains("querySelectorAll(scopeSelector)"))
      assert_true(expr.contains("scopeSelector = \"section\""))
      assert_true(expr.contains("aria-labelledby"))
      assert_true(expr.contains("aria-label"))
      assert_true(expr.contains("parts.join"))
      assert_true(expr.contains("label[for=\""))
      assert_true(expr.contains("labelledByText"))
      assert_true(expr.contains("accessibleName"))
      assert_true(expr.contains("innerText"))
      assert_true(expr.contains("compareDocumentPosition"))
      assert_true(expr.contains("is_visible"))
      assert_true(expr.contains("getClientRects"))
      assert_true(expr.contains("getBoundingClientRect"))
      assert_true(expr.contains("aria-hidden"))
      assert_true(expr.contains("labelDistance"))
      assert_true(expr.contains("domDistance"))
      assert_true(expr.contains("labelNodesFor"))
      assert_true(expr.contains("labelScore"))
      assert_true(expr.contains("return 1; } let parent"))
      assert_true(expr.contains("node.contains"))
      assert_true(
        expr.contains("visibility === 'collapse' && (cur.tagName === 'TABLE'"),
      )
      assert_true(expr.contains("replace(/\\s+/g"))
      assert_true(expr.contains("ids.indexOf"))
      assert_true(expr.contains("u00a0"))
      assert_true(expr.contains("u200B"))
      assert_true(expr.contains("parts.length > 0"))
    }
    None => assert_true(false)
  }
}

///|
async test "navigation wait and network events" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"type\":\"event\",\"method\":\"network.beforeRequestSent\",\"params\":{\"context\":\"ctx-1\",\"request\":{\"url\":\"https://example.com/request\",\"method\":\"GET\",\"headers\":[{\"name\":\"accept\",\"value\":\"text/html\"}]}}}",
      "{\"type\":\"event\",\"method\":\"network.responseStarted\",\"params\":{\"context\":\"ctx-1\",\"response\":{\"url\":\"https://example.com/final\",\"status\":200,\"status_text\":\"OK\",\"headers\":[{\"name\":\"content-type\",\"value\":\"text/html\"}]}}}",
      "{\"type\":\"event\",\"method\":\"network.responseCompleted\",\"params\":{\"context\":\"ctx-1\",\"response\":{\"url\":\"https://example.com/final\",\"status\":200,\"status_text\":\"OK\",\"headers\":[{\"name\":\"content-type\",\"value\":\"text/html\"}]}}}",
      "{\"type\":\"event\",\"method\":\"browsingContext.domContentLoaded\",\"params\":{\"context\":\"ctx-1\",\"url\":\"https://example.com/final\"}}",
      "{\"type\":\"event\",\"method\":\"browsingContext.load\",\"params\":{\"context\":\"ctx-1\",\"url\":\"https://example.com/final\"}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"navigation\":\"nav-1\",\"url\":\"https://example.com/start\"}}",
      "{\"id\":5,\"type\":\"success\",\"result\":{\"result\":{\"type\":\"string\",\"value\":\"complete\"}}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let requests : Ref[Array[String]] = { val: [], }
  let responses : Ref[Array[Int]] = { val: [], }
  let completed : Ref[Array[Int]] = { val: [], }
  page.on_request(fn(req : Request) { requests.val.push(req.url()) })
  page.on_response(fn(resp : Response) { responses.val.push(resp.status()) })
  page.on_response_completed(fn(resp : Response) {
    completed.val.push(resp.status())
  })
  let _ = page.goto("https://example.com/start")
  page.wait_for_load_state(state="domcontentloaded")
  let nav = page.wait_for_navigation(wait_until="load")
  match nav {
    Some(resp) => inspect(resp.url(), content="https://example.com/final")
    None => assert_true(false)
  }
  inspect(page.url(), content="https://example.com/final")
  assert_true(requests.val.length() == 1)
  inspect(requests.val[0], content="https://example.com/request")
  assert_true(responses.val.length() == 1)
  assert_eq(responses.val[0], 200)
  assert_true(completed.val.length() == 1)
  assert_eq(completed.val[0], 200)
}

///|
async test "wait_for_request and wait_for_response" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"type\":\"event\",\"method\":\"network.beforeRequestSent\",\"params\":{\"context\":\"ctx-1\",\"request\":{\"url\":\"https://example.com/request\",\"method\":\"GET\",\"headers\":[{\"name\":\"accept\",\"value\":\"text/html\"}]}}}",
      "{\"type\":\"event\",\"method\":\"network.responseStarted\",\"params\":{\"context\":\"ctx-1\",\"response\":{\"url\":\"https://example.com/final\",\"status\":200,\"status_text\":\"OK\",\"headers\":[{\"name\":\"content-type\",\"value\":\"text/html\"}]}}}",
      "{\"type\":\"event\",\"method\":\"network.responseCompleted\",\"params\":{\"context\":\"ctx-1\",\"response\":{\"url\":\"https://example.com/final\",\"status\":204,\"status_text\":\"No Content\",\"headers\":[{\"name\":\"content-type\",\"value\":\"text/plain\"}]}}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"navigation\":\"nav-1\",\"url\":\"https://example.com/start\"}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let _ = page.goto("https://example.com/start")
  match page.wait_for_request("https://example.com/request") {
    Some(req) => inspect(req.url(), content="https://example.com/request")
    None => assert_true(false)
  }
  match page.wait_for_response("https://example.com/final") {
    Some(resp) => {
      inspect(resp.url(), content="https://example.com/final")
      assert_eq(resp.status(), 200)
    }
    None => assert_true(false)
  }
  match
    page.wait_for_response("https://example.com/final", stage="completed", predicate=fn(
      resp : Response,
    ) {
      resp.status() == 204
    }) {
    Some(resp) => assert_eq(resp.status(), 204)
    None => assert_true(false)
  }
}

///|
async test "wait_for_request match modes" {
  let sent : Ref[Array[String]] = { val: [], }
  let recv_queue : Ref[Array[String]] = {
    val: [
      "{\"id\":1,\"type\":\"success\",\"result\":{\"sessionId\":\"sid-1\",\"capabilities\":{}}}",
      "{\"id\":2,\"type\":\"success\",\"result\":{}}", "{\"id\":3,\"type\":\"success\",\"result\":{\"context\":\"ctx-1\"}}",
      "{\"type\":\"event\",\"method\":\"network.beforeRequestSent\",\"params\":{\"context\":\"ctx-1\",\"request\":{\"url\":\"https://example.com/api/v1/items\",\"method\":\"GET\",\"headers\":[]}}}",
      "{\"type\":\"event\",\"method\":\"network.beforeRequestSent\",\"params\":{\"context\":\"ctx-1\",\"request\":{\"url\":\"https://example.com/api/v1/save\",\"method\":\"POST\",\"headers\":[]}}}",
      "{\"type\":\"event\",\"method\":\"network.beforeRequestSent\",\"params\":{\"context\":\"ctx-1\",\"request\":{\"url\":\"https://example.com/assets/app.js\",\"method\":\"GET\",\"headers\":[]}}}",
      "{\"type\":\"event\",\"method\":\"network.beforeRequestSent\",\"params\":{\"context\":\"ctx-1\",\"request\":{\"url\":\"https://example.com/api/v2/items\",\"method\":\"GET\",\"headers\":[]}}}",
      "{\"type\":\"event\",\"method\":\"network.responseStarted\",\"params\":{\"context\":\"ctx-1\",\"response\":{\"url\":\"https://example.com/api/v1/items\",\"status\":200,\"status_text\":\"OK\",\"headers\":[]}}}",
      "{\"type\":\"event\",\"method\":\"network.responseStarted\",\"params\":{\"context\":\"ctx-1\",\"response\":{\"url\":\"https://example.com/assets/app.js\",\"status\":200,\"status_text\":\"OK\",\"headers\":[]}}}",
      "{\"id\":4,\"type\":\"success\",\"result\":{\"navigation\":\"nav-1\",\"url\":\"https://example.com/start\"}}",
    ],
  }
  let transport = make_mock_transport(sent, recv_queue)
  let browser = chromium().connect_with_transport(transport)
  let page = browser.new_page()
  let _ = page.goto("https://example.com/start")
  match page.wait_for_request("example.com/api", match_mode="contains") {
    Some(req) => inspect(req.url(), content="https://example.com/api/v1/items")
    None => assert_true(false)
  }
  match
    page.wait_for_request("https://example.com/api/v1/*", predicate=fn(
      req : Request,
    ) {
      req.method_() == "POST"
    }) {
    Some(req) => inspect(req.url(), content="https://example.com/api/v1/save")
    None => assert_true(false)
  }
  match page.wait_for_request("https://example.com/*") {
    Some(req) => inspect(req.url(), content="https://example.com/assets/app.js")
    None => assert_true(false)
  }
  match
    page.wait_for_request(
      "^https://example.com/api/.*items$",
      match_mode="regex",
    ) {
    Some(req) => inspect(req.url(), content="https://example.com/api/v2/items")
    None => assert_true(false)
  }
  match page.wait_for_response("assets/app.js", match_mode="contains") {
    Some(resp) =>
      inspect(resp.url(), content="https://example.com/assets/app.js")
    None => assert_true(false)
  }
}
