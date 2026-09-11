///|
/// Page methods

///|
/// Navigate to URL
/// See: https://playwright.dev/docs/api/class-page#page-goto
pub async fn Page::goto(
  self : Page,
  url : String,
  timeout? : Int,
  wait_until? : String,
  referer? : String,
) -> Response? {
  consume(referer)
  let state = self.state.val
  let result = state.browser.state.val.client.browsing_context_navigate(
    state.context_id,
    url,
    wait=wait_until.unwrap_or("complete"),
  )
  match result {
    Ok(nav) => {
      state.url = nav.url
      // Try to find the matching network response (collected by event handler)
      let timeout_ms = timeout.unwrap_or(5000)
      match self.wait_for_response(url, timeout=timeout_ms, stage="completed") {
        Some(resp) => Some(resp)
        None =>
          // Fallback: check response_completed_events directly
          match self.take_response_completed_event(url, "starts_with", None) {
            Some(resp) => Some(resp)
            None =>
              // Last resort: check response_events (started)
              match self.take_response_event(url, "starts_with", None) {
                Some(resp) => Some(resp)
                None => Some(make_response(nav.url))
              }
          }
      }
    }
    Err(_) => None
  }
}

///|
/// Reload page
pub async fn Page::reload(
  self : Page,
  timeout? : Int,
  wait_until? : String,
) -> Response? {
  consume((timeout, wait_until))
  let state = self.state.val
  let _ = state.browser.state.val.client.browsing_context_reload(
    state.context_id,
  )
  Some(make_response(state.url))
}

///|
/// Go back in history
pub async fn Page::go_back(
  self : Page,
  timeout? : Int,
  wait_until? : String,
) -> Response? {
  consume((timeout, wait_until))
  let _ = self.evaluate("history.back()")
  None
}

///|
/// Go forward in history
pub async fn Page::go_forward(
  self : Page,
  timeout? : Int,
  wait_until? : String,
) -> Response? {
  consume((timeout, wait_until))
  let _ = self.evaluate("history.forward()")
  None
}

///|
/// Get page URL
pub fn Page::url(self : Page) -> String {
  self.state.val.url
}

///|
/// Get page title
pub async fn Page::title(self : Page) -> String {
  match self.eval_string("document.title") {
    Some(value) => value
    None => ""
  }
}

///|
/// Get page content (HTML)
pub async fn Page::content(self : Page) -> String {
  match self.eval_string("document.documentElement.outerHTML") {
    Some(value) => value
    None => ""
  }
}

///|
/// Set page content
pub async fn Page::set_content(
  self : Page,
  html : String,
  timeout? : Int,
  wait_until? : String,
) -> Unit {
  consume((timeout, wait_until))
  let expr = "(html) => { document.open(); document.write(html); document.close(); }"
  let args : Array[Json] = [
    Json::object({ "type": Json::string("string"), "value": Json::string(html) }),
  ]
  let _ = self.call_function(expr, args)
}

///|
/// Get locator for CSS selector or text
pub fn Page::locator(self : Page, selector : String) -> Locator {
  let state : LocatorState = {
    page: self,
    selector,
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: None,
    label_text: None,
    label_text_exact: false,
    label_scope_selector: None,
  }
  { state: { val: state, }, }
}

///|
/// Get locator by role
pub fn Page::get_by_role(
  self : Page,
  role : String,
  name? : String,
  exact? : Bool,
) -> Locator {
  consume(exact)
  let selector = "[role=" + js_string_literal(role) + "]"
  let base = self.locator(selector)
  match name {
    Some(text) => base.get_by_text(text, exact?)
    None => base
  }
}

///|
/// Get locator by text
pub fn Page::get_by_text(self : Page, text : String, exact? : Bool) -> Locator {
  let exact_flag = match exact {
    Some(true) => true
    _ => false
  }
  let state : LocatorState = {
    page: self,
    selector: "*",
    index: None,
    has_text: Some(text),
    has_text_exact: exact_flag,
    has_not_text: None,
    label_text: None,
    label_text_exact: false,
    label_scope_selector: None,
  }
  { state: { val: state, }, }
}

///|
/// Get locator by label
pub fn Page::get_by_label(self : Page, text : String, exact? : Bool) -> Locator {
  let exact_flag = match exact {
    Some(true) => true
    _ => false
  }
  let state : LocatorState = {
    page: self,
    selector: "label",
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: None,
    label_text: Some(text),
    label_text_exact: exact_flag,
    label_scope_selector: None,
  }
  { state: { val: state, }, }
}

///|
/// Get locator by placeholder
pub fn Page::get_by_placeholder(
  self : Page,
  text : String,
  exact? : Bool,
) -> Locator {
  consume(exact)
  let selector = "[placeholder=" + js_string_literal(text) + "]"
  let state : LocatorState = {
    page: self,
    selector,
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: None,
    label_text: None,
    label_text_exact: false,
    label_scope_selector: None,
  }
  { state: { val: state, }, }
}

///|
/// Get locator by alt text
pub fn Page::get_by_alt_text(
  self : Page,
  text : String,
  exact? : Bool,
) -> Locator {
  consume(exact)
  let selector = "[alt=" + js_string_literal(text) + "]"
  let state : LocatorState = {
    page: self,
    selector,
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: None,
    label_text: None,
    label_text_exact: false,
    label_scope_selector: None,
  }
  { state: { val: state, }, }
}

///|
/// Get locator by title
pub fn Page::get_by_title(self : Page, text : String, exact? : Bool) -> Locator {
  consume(exact)
  let selector = "[title=" + js_string_literal(text) + "]"
  let state : LocatorState = {
    page: self,
    selector,
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: None,
    label_text: None,
    label_text_exact: false,
    label_scope_selector: None,
  }
  { state: { val: state, }, }
}

///|
/// Get locator by test ID
pub fn Page::get_by_test_id(self : Page, testId : String) -> Locator {
  let selector = "[data-testid=" + js_string_literal(testId) + "]"
  let state : LocatorState = {
    page: self,
    selector,
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: None,
    label_text: None,
    label_text_exact: false,
    label_scope_selector: None,
  }
  { state: { val: state, }, }
}

///|
/// Subscribe network event
pub fn Page::on_network_event(
  self : Page,
  handler : (NetworkEvent) -> Unit,
) -> Unit {
  self.state.val.network_listeners.push(handler)
}

///|
/// Subscribe request event
pub fn Page::on_request(self : Page, handler : (Request) -> Unit) -> Unit {
  self.on_network_event(fn(evt : NetworkEvent) {
    match evt {
      NetworkEvent::Request(req) => handler(req)
      _ => ()
    }
  })
}

///|
/// Subscribe response event
pub fn Page::on_response(self : Page, handler : (Response) -> Unit) -> Unit {
  self.on_network_event(fn(evt : NetworkEvent) {
    match evt {
      NetworkEvent::Response(resp) => handler(resp)
      _ => ()
    }
  })
}

///|
/// Subscribe response completed event
pub fn Page::on_response_completed(
  self : Page,
  handler : (Response) -> Unit,
) -> Unit {
  self.on_network_event(fn(evt : NetworkEvent) {
    match evt {
      NetworkEvent::ResponseCompleted(resp) => handler(resp)
      _ => ()
    }
  })
}

///|
/// Click on element
pub async fn Page::click(
  self : Page,
  selector : String,
  button? : String,
  click_count? : Int,
  delay? : Int,
  force? : Bool,
  modifiers? : Array[String],
  no_wait_after? : Bool,
  position? : (Double, Double),
  timeout? : Int,
  trial? : Bool,
) -> Unit {
  consume(
    (
      button, click_count, delay, force, modifiers, no_wait_after, position, timeout,
      trial,
    ),
  )
  let locator = self.locator(selector)
  locator.click()
}

///|
/// Double click on element
pub async fn Page::dblclick(
  self : Page,
  selector : String,
  timeout? : Int,
  force? : Bool,
) -> Unit {
  consume((timeout, force))
  let locator = self.locator(selector)
  locator.dblclick()
}

///|
/// Fill input
pub async fn Page::fill(
  self : Page,
  selector : String,
  value : String,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  let locator = self.locator(selector)
  locator.fill(value)
}

///|
/// Type text (keystroke by keystroke)
pub async fn Page::type_(
  self : Page,
  selector : String,
  text : String,
  delay? : Int,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((delay, no_wait_after, timeout))
  let locator = self.locator(selector)
  locator.type_(text)
}

///|
/// Press key
pub async fn Page::press(
  self : Page,
  selector : String,
  key : String,
  delay? : Int,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((delay, no_wait_after, timeout))
  let locator = self.locator(selector)
  locator.press(key)
}

///|
/// Check checkbox
pub async fn Page::check(
  self : Page,
  selector : String,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  let locator = self.locator(selector)
  locator.check()
}

///|
/// Uncheck checkbox
pub async fn Page::uncheck(
  self : Page,
  selector : String,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  let locator = self.locator(selector)
  locator.uncheck()
}

///|
/// Select option(s) in dropdown
pub async fn Page::select_option(
  self : Page,
  selector : String,
  values : Array[SelectOption],
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Array[String] {
  consume((self, selector, values, force, no_wait_after, timeout))
  async_noop()
  []
}

///|
/// Hover over element
pub async fn Page::hover(
  self : Page,
  selector : String,
  force? : Bool,
  modifiers? : Array[String],
  position? : (Double, Double),
  timeout? : Int,
  trial? : Bool,
) -> Unit {
  consume((force, modifiers, position, timeout, trial))
  let locator = self.locator(selector)
  locator.hover()
}

///|
/// Focus element
pub async fn Page::focus(
  self : Page,
  selector : String,
  timeout? : Int,
) -> Unit {
  consume(timeout)
  let locator = self.locator(selector)
  locator.focus()
}

///|
/// Wait for selector
pub async fn Page::wait_for_selector(
  self : Page,
  selector : String,
  state? : String,
  timeout? : Int,
  strict? : Bool,
) -> ElementHandle? {
  let strict_mode = match strict {
    Some(true) => true
    _ => false
  }
  let desired = match state {
    Some("attached") => "attached"
    Some("detached") => "detached"
    Some("hidden") => "hidden"
    Some("visible") => "visible"
    _ => "visible"
  }
  let timeout_ms = match timeout {
    Some(value) => value
    None => 30_000
  }
  let start = @async.now()
  let result = for attempt = 0 {
    let nodes = self.locate_nodes(selector)
    let found = nodes.length() > 0
    if strict_mode && nodes.length() > 1 {
      raise PlaywrightError::StrictModeViolation(
        selector~,
        count=nodes.length(),
      )
    }
    match desired {
      "attached" =>
        if found {
          let handle = JSHandle::from_page(self, nodes[0])
          break handle.as_element()
        }
      "detached" => if !found { break None }
      "hidden" =>
        if !found {
          break None
        } else {
          match self.is_node_visible(nodes[0]) {
            Some(true) => ()
            Some(false) => break None
            None => ()
          }
        }
      "visible" =>
        if found {
          match self.is_node_visible(nodes[0]) {
            Some(true) => {
              let handle = JSHandle::from_page(self, nodes[0])
              break handle.as_element()
            }
            _ => ()
          }
        }
      _ => ()
    }
    if timeout_ms <= 0 {
      break None
    }
    let elapsed = @async.now() - start
    if elapsed >= timeout_ms.to_int64() {
      break None
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
  result
}

///|
/// Wait for load state
pub async fn Page::wait_for_load_state(
  self : Page,
  state? : String,
  timeout? : Int,
) -> Unit {
  let desired = match state {
    Some("domcontentloaded") => "domcontentloaded"
    Some("load") => "load"
    Some("networkidle") => "load"
    Some(value) => value
    None => "load"
  }
  match self.eval_string("document.readyState") {
    Some("complete") =>
      if desired == "load" || desired == "networkidle" {
        return
      }
    Some("interactive") => if desired == "domcontentloaded" { return }
    _ => ()
  }
  match timeout {
    Some(value) => {
      let _ = self.wait_for_navigation(timeout=value, wait_until=desired)
    }
    None => {
      let _ = self.wait_for_navigation(wait_until=desired)
    }
  }
}

///|
/// Wait for navigation
pub async fn Page::wait_for_navigation(
  self : Page,
  timeout? : Int,
  url? : String,
  wait_until? : String,
) -> Response? {
  let wait_method = match wait_until {
    Some("domcontentloaded") => "browsingContext.domContentLoaded"
    Some("load") => "browsingContext.load"
    Some("networkidle") => "browsingContext.load"
    Some(value) => value
    None => "browsingContext.load"
  }
  let timeout_ms = match timeout {
    Some(value) => value
    None => 30_000
  }
  let start = @async.now()
  let result = for attempt = 0 {
    match self.take_navigation_event(Some(wait_method), url) {
      Some(evt) => {
        self.state.val.url = evt.url
        break Some(make_response(evt.url))
      }
      None => ()
    }
    match url {
      Some(target) =>
        if self.state.val.url == target {
          break Some(make_response(target))
        }
      None => ()
    }
    if timeout_ms <= 0 {
      break None
    }
    let elapsed = @async.now() - start
    if elapsed >= timeout_ms.to_int64() {
      break None
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
  result
}

///|
/// Wait for URL
pub async fn Page::wait_for_url(
  self : Page,
  url : String,
  timeout? : Int,
  wait_until? : String,
) -> Unit {
  consume(wait_until)
  if self.state.val.url == url {
    return
  }
  let timeout_ms = match timeout {
    Some(value) => value
    None => 30_000
  }
  let start = @async.now()
  let _ = for attempt = 0 {
    match self.take_navigation_event(None, Some(url)) {
      Some(evt) => {
        self.state.val.url = evt.url
        break ()
      }
      None => ()
    }
    if self.state.val.url == url {
      break ()
    }
    if timeout_ms <= 0 {
      break ()
    }
    let elapsed = @async.now() - start
    if elapsed >= timeout_ms.to_int64() {
      break ()
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
}

///|
/// Wait for network request
pub async fn Page::wait_for_request(
  self : Page,
  url : String,
  timeout? : Int,
  match_mode? : String,
  predicate? : (Request) -> Bool,
) -> Request? {
  let match_mode = resolve_match_mode(url, match_mode)
  let timeout_ms = match timeout {
    Some(value) => value
    None => 30_000
  }
  let start = @async.now()
  let result = for attempt = 0 {
    match self.take_request_event(url, match_mode, predicate) {
      Some(req) => break Some(req)
      None => ()
    }
    if timeout_ms <= 0 {
      break None
    }
    let elapsed = @async.now() - start
    if elapsed >= timeout_ms.to_int64() {
      break None
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
  result
}

///|
/// Wait for network response
pub async fn Page::wait_for_response(
  self : Page,
  url : String,
  timeout? : Int,
  match_mode? : String,
  stage? : String,
  predicate? : (Response) -> Bool,
) -> Response? {
  let match_mode = resolve_match_mode(url, match_mode)
  let resolved_stage = resolve_response_stage(stage)
  let timeout_ms = match timeout {
    Some(value) => value
    None => 30_000
  }
  let start = @async.now()
  let result = for attempt = 0 {
    let matched = if resolved_stage == "completed" {
      self.take_response_completed_event(url, match_mode, predicate)
    } else {
      self.take_response_event(url, match_mode, predicate)
    }
    match matched {
      Some(resp) => break Some(resp)
      None => ()
    }
    if timeout_ms <= 0 {
      break None
    }
    let elapsed = @async.now() - start
    if elapsed >= timeout_ms.to_int64() {
      break None
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
  result
}

///|
/// Wait for timeout
pub async fn Page::wait_for_timeout(self : Page, timeout : Int) -> Unit {
  consume(self)
  sleep_ms(timeout)
}

///|
/// Wait for function to return truthy value
pub async fn Page::wait_for_function(
  self : Page,
  page_function : String,
  arg? : Json,
  polling? : Int,
  timeout? : Int,
) -> Json {
  consume((polling, timeout))
  match arg {
    Some(value) => self.evaluate(page_function, arg=value)
    None => self.evaluate(page_function)
  }
}

///|
/// Evaluate JavaScript in page context.
/// If page_function looks like a function (starts with "function", "async", "(" or "=>"),
/// uses script.callFunction for proper invocation. Otherwise uses script.evaluate.
pub async fn Page::evaluate(
  self : Page,
  page_function : String,
  arg? : Json,
) -> Json {
  let state = self.state.val
  let client = state.browser.state.val.client
  let ctx = state.context_id
  let result = if is_function_expression(page_function) {
    // Use callFunction for arrow functions, function expressions, etc.
    let args : Array[Json] = match arg {
      Some(a) => [a]
      None => []
    }
    client.script_call_function(page_function, ctx, arguments=args)
  } else {
    client.script_evaluate(page_function, ctx)
  }
  match result {
    Ok(json) =>
      match json_get_object(json, "result") {
        Some(value) => remote_value_to_json(value)
        None => Json::null()
      }
    Err(_) => Json::null()
  }
}

///|
/// Evaluate JavaScript and return handle
pub async fn Page::evaluate_handle(
  self : Page,
  page_function : String,
  arg? : Json,
) -> JSHandle {
  consume(arg)
  let state = self.state.val
  let result = state.browser.state.val.client.script_evaluate(
    page_function,
    state.context_id,
  )
  match result {
    Ok(json) =>
      match json_get_object(json, "result") {
        Some(value) => JSHandle::from_page(self, value)
        None => JSHandle::from_page(self, Json::null())
      }
    Err(_) => JSHandle::from_page(self, Json::null())
  }
}

///|
/// Take screenshot
pub async fn Page::screenshot(
  self : Page,
  path? : String,
  type_? : String,
  quality? : Int,
  full_page? : Bool,
  clip? : Clip,
  omit_background? : Bool,
  timeout? : Int,
  scale? : String,
) -> ResponseBody {
  consume(
    (
      self, path, type_, quality, full_page, clip, omit_background, timeout, scale,
    ),
  )
  async_noop()
  ResponseBody::bytes(b"")
}

///|
/// Generate PDF (Chromium only)
pub async fn Page::pdf(
  self : Page,
  path? : String,
  scale? : Double,
  display_header_footer? : Bool,
  header_template? : String,
  footer_template? : String,
  print_background? : Bool,
  landscape? : Bool,
  page_ranges? : String,
  format? : String,
  width? : String,
  height? : String,
  margin? : Margin,
  prefer_css_page_size? : Bool,
) -> ResponseBody {
  consume(
    (
      self, path, scale, display_header_footer, header_template, footer_template,
      print_background, landscape, page_ranges, format, width, height, margin, prefer_css_page_size,
    ),
  )
  async_noop()
  ResponseBody::bytes(b"")
}

///|
/// Get all console messages collected since page creation
pub fn Page::console_messages(self : Page) -> Array[ConsoleMessage] {
  self.state.val.console_messages.copy()
}

///|
/// Get console error messages (level == "error")
pub fn Page::console_errors(self : Page) -> Array[ConsoleMessage] {
  self.state.val.console_messages.filter(fn(m) { m.level == "error" })
}

///|
/// Clear collected console messages
pub fn Page::clear_console(self : Page) -> Unit {
  self.state.val.console_messages.clear()
}

///|
/// Fill an input element by selector. Uses script.evaluate with single-quote escaping
/// to avoid double-quote issues in BiDi expression evaluation.
pub async fn Page::fill_input(
  self : Page,
  selector : String,
  value : String,
) -> Unit {
  // Use single quotes for selector to avoid escaping issues with double-quote attributes
  let sel_escaped = selector.replace(old="'", new="\\'")
  let val_escaped = value
    .replace(old="'", new="\\'")
    .replace(old="\\", new="\\\\")
  let expr = "(function(){var el=document.querySelector('" +
    sel_escaped +
    "');if(!el)return;el.focus();el.value='" +
    val_escaped +
    "';el.dispatchEvent(new InputEvent('input',{bubbles:true,data:'" +
    val_escaped +
    "',inputType:'insertText'}));el.dispatchEvent(new Event('change',{bubbles:true}))})()"
  let state = self.state.val
  let _ = state.browser.state.val.client.script_evaluate(expr, state.context_id)
}

///|
/// Ensure Luna island hydration is complete.
/// Calls __LUNA_SCAN__ if available, then waits for the specified timeout.
/// Use after goto() when testing hydrated islands.
pub async fn Page::ensure_hydration(self : Page, timeout? : Int = 5000) -> Unit {
  self.wait_for_timeout(timeout)
  let _ = self.evaluate(
    "() => { if (window.__LUNA_SCAN__) window.__LUNA_SCAN__(); }",
  )
  self.wait_for_timeout(500)
}

///|
/// Wait until page content contains a specific string.
/// Polls content() until the string is found or timeout.
pub async fn Page::wait_for_content(
  self : Page,
  text : String,
  timeout? : Int = 10000,
) -> Bool {
  let start = @async.now()
  for ;; {
    let content = self.content()
    if content.contains(text) {
      return true
    }
    let elapsed = @async.now() - start
    if elapsed >= timeout.to_int64() {
      return false
    }
    self.wait_for_timeout(200)
  }
}

///|
/// Click an element inside a shadow DOM host.
/// Uses evaluate to pierce shadow roots.
pub async fn Page::shadow_click(
  self : Page,
  host_selector : String,
  inner_selector : String,
) -> Unit {
  let expr = "() => { const el = document.querySelector(" +
    js_string_literal(host_selector) +
    ")?.shadowRoot?.querySelector(" +
    js_string_literal(inner_selector) +
    "); if (el) { el.dispatchEvent(new MouseEvent('click', {bubbles:true,composed:true})); el.click(); } }"
  let _ = self.evaluate(expr)
}

///|
/// Get text content from an element inside a shadow DOM host.
pub async fn Page::shadow_text(
  self : Page,
  host_selector : String,
  inner_selector : String,
) -> String {
  let expr = "() => document.querySelector(" +
    js_string_literal(host_selector) +
    ")?.shadowRoot?.querySelector(" +
    js_string_literal(inner_selector) +
    ")?.textContent || ''"
  match self.evaluate(expr) {
    String(s) => s
    _ => ""
  }
}

///|
/// Fetch a URL from the page context and return status + body text.
#label_migration(http_method, alias=method)
pub async fn Page::fetch_text(
  self : Page,
  url : String,
  http_method? : String = "GET",
  body? : String,
  headers? : Array[(String, String)],
) -> (Int, String) {
  let body_js = match body {
    Some(b) => js_string_literal(b)
    None => "undefined"
  }
  // Use synchronous XMLHttpRequest (evaluate doesn't await Promises reliably)
  let result = self.evaluate(
    "() => { const xhr = new XMLHttpRequest(); xhr.open(" +
    js_string_literal(http_method) +
    ", " +
    js_string_literal(url) +
    ", false); " + // false = synchronous
    (match headers {
      Some(h) => {
        let buf = StringBuilder()
        for pair in h {
          buf.write_string("xhr.setRequestHeader(")
          buf.write_string(js_string_literal(pair.0))
          buf.write_string(",")
          buf.write_string(js_string_literal(pair.1))
          buf.write_string(");")
        }
        buf.to_string()
      }
      None => ""
    }) +
    "xhr.send(" +
    body_js +
    "); return { status: xhr.status, body: xhr.responseText }; }",
  )
  match result {
    Object(m) => {
      let status = match m.get("status") {
        Some(Number(n, ..)) => n.to_int()
        _ => 0
      }
      let text = match m.get("body") {
        Some(String(s)) => s
        _ => ""
      }
      (status, text)
    }
    _ => (0, "")
  }
}

///|
/// Fetch a URL and parse response as JSON.
#label_migration(http_method, alias=method)
pub async fn Page::fetch_json(
  self : Page,
  url : String,
  http_method? : String = "GET",
  body? : String,
  headers? : Array[(String, String)],
) -> (Int, Json) {
  let (status, text) = self.fetch_text(url, http_method~, body?, headers?)
  let json = @json.parse(text) catch { _ => Json::null() }
  (status, json)
}

///|
/// Close page
pub async fn Page::close(self : Page, run_before_unload? : Bool) -> Unit {
  consume(run_before_unload)
  let state = self.state.val
  let _ = state.browser.state.val.client.browsing_context_close(
    state.context_id,
  )
  let _ = state.context
}

///|
/// Close page with error callback (for use with defer)
/// Note: This initiates close but doesn't wait for completion
pub fn Page::close_with_error_callback(
  self : Page,
  on_error : (Error) -> Unit,
) -> Unit {
  consume((self, on_error))
}

///|
/// Check if page is closed
pub fn Page::is_closed(self : Page) -> Bool {
  consume(self)
  false
}

///|
/// Bring page to front
pub async fn Page::bring_to_front(self : Page) -> Unit {
  consume(self)
  async_noop()
}

///|
/// Set viewport size
pub async fn Page::set_viewport_size(
  self : Page,
  width : Int,
  height : Int,
) -> Unit {
  consume((self, width, height))
  async_noop()
}

///|
/// Get viewport size
pub fn Page::viewport_size(self : Page) -> (Int, Int)? {
  consume(self)
  None
}

///|
/// Set extra HTTP headers
pub async fn Page::set_extra_http_headers(
  self : Page,
  headers : Headers,
) -> Unit {
  consume((self, headers))
  async_noop()
}

///|
/// Add script tag
pub async fn Page::add_script_tag(
  self : Page,
  url? : String,
  path? : String,
  content? : String,
  type_? : String,
) -> Json {
  consume((self, url, path, content, type_))
  async_noop()
  Json::null()
}

///|
/// Add style tag
pub async fn Page::add_style_tag(
  self : Page,
  url? : String,
  path? : String,
  content? : String,
) -> Json {
  consume((self, url, path, content))
  async_noop()
  Json::null()
}

///|
/// Expose function to page
pub async fn Page::expose_function(
  self : Page,
  name : String,
  callback : Json,
) -> Unit {
  consume((self, name, callback))
  async_noop()
}

///|
/// Set default navigation timeout
pub fn Page::set_default_navigation_timeout(self : Page, timeout : Int) -> Unit {
  consume((self, timeout))
}

///|
/// Set default timeout
pub fn Page::set_default_timeout(self : Page, timeout : Int) -> Unit {
  consume((self, timeout))
}

///|
async fn Page::eval_string(self : Page, expression : String) -> String? {
  let state = self.state.val
  let result = state.browser.state.val.client.script_evaluate(
    expression,
    state.context_id,
  )
  match result {
    Ok(json) =>
      match json_get_object(json, "result") {
        Some(value) => remote_value_to_string(value)
        None => None
      }
    Err(_) => None
  }
}

///|
async fn Page::call_function(
  self : Page,
  function_declaration : String,
  args : Array[Json],
) -> Unit {
  let state = self.state.val
  let _ = state.browser.state.val.client.script_call_function(
    function_declaration,
    state.context_id,
    arguments=args,
  )
}

///|
async fn Page::locate_nodes(self : Page, selector : String) -> Array[Json] {
  let state = self.state.val
  let locator = @bidi.Locator::css(selector)
  let result = state.browser.state.val.client.browsing_context_locate_nodes_typed(
    state.context_id,
    locator,
  )
  match result {
    Ok(json) => json_get_array(json, "nodes").unwrap_or([])
    Err(_) => []
  }
}

///|
async fn Page::is_node_visible(self : Page, node : Json) -> Bool? {
  let state = self.state.val
  let args : Array[Json] = [node]
  let result = state.browser.state.val.client.script_call_function(
    "(node) => { if (!node || !(node instanceof Element)) return false; if (node.hidden) return false; let el = node; while (el) { if (el.hidden) return false; if (el.getAttribute && el.getAttribute('aria-hidden') === 'true') return false; const style = getComputedStyle(el); if (!style) return false; const opacity = parseFloat(style.opacity || '1'); if (opacity <= 0) return false; if (style.visibility === 'hidden' || style.visibility === 'collapse' || style.display === 'none' || style.contentVisibility === 'hidden') return false; if (el instanceof HTMLDetailsElement && !el.open) { const summary = el.querySelector('summary'); if (summary && !summary.contains(node)) return false; } el = el.parentElement; } if (node.getClientRects().length === 0) return false; const rect = node.getBoundingClientRect(); return rect.width > 0 && rect.height > 0; }",
    state.context_id,
    arguments=args,
  )
  match result {
    Ok(json) =>
      match json_get_object(json, "result") {
        Some(value) =>
          match remote_value_to_json(value) {
            True => Some(true)
            False => Some(false)
            _ => None
          }
        None => None
      }
    Err(_) => None
  }
}

///|
fn Page::take_navigation_event(
  self : Page,
  event_name : String?,
  url : String?,
) -> NavigationEvent? {
  let events = self.state.val.navigation_events
  let mut index = 0
  while index < events.length() {
    let evt = events[index]
    let event_ok = match event_name {
      Some(value) => evt.event_name == value
      None => true
    }
    let url_ok = match url {
      Some(value) => evt.url == value
      None => true
    }
    if event_ok && url_ok {
      let _ = events.remove(index)
      return Some(evt)
    }
    index = index + 1
  }
  None
}

///|
fn Page::take_request_event(
  self : Page,
  pattern : String,
  match_mode : String,
  predicate : ((Request) -> Bool)?,
) -> Request? {
  let events = self.state.val.request_events
  let mut index = 0
  while index < events.length() {
    let req = events[index]
    let url_ok = url_matches(req.url(), pattern, match_mode)
    let predicate_ok = match predicate {
      Some(pred) => pred(req)
      None => true
    }
    if url_ok && predicate_ok {
      let _ = events.remove(index)
      return Some(req)
    }
    index = index + 1
  }
  None
}

///|
fn Page::take_response_event(
  self : Page,
  pattern : String,
  match_mode : String,
  predicate : ((Response) -> Bool)?,
) -> Response? {
  let events = self.state.val.response_events
  let mut index = 0
  while index < events.length() {
    let resp = events[index]
    let url_ok = url_matches(resp.url(), pattern, match_mode)
    let predicate_ok = match predicate {
      Some(pred) => pred(resp)
      None => true
    }
    if url_ok && predicate_ok {
      let _ = events.remove(index)
      return Some(resp)
    }
    index = index + 1
  }
  None
}

///|
fn Page::take_response_completed_event(
  self : Page,
  pattern : String,
  match_mode : String,
  predicate : ((Response) -> Bool)?,
) -> Response? {
  let events = self.state.val.response_completed_events
  let mut index = 0
  while index < events.length() {
    let resp = events[index]
    let url_ok = url_matches(resp.url(), pattern, match_mode)
    let predicate_ok = match predicate {
      Some(pred) => pred(resp)
      None => true
    }
    if url_ok && predicate_ok {
      let _ = events.remove(index)
      return Some(resp)
    }
    index = index + 1
  }
  None
}

///|
fn resolve_match_mode(pattern : String, match_mode : String?) -> String {
  match match_mode {
    Some(mode) => {
      let lower = mode.to_lower()
      if lower == "contains" || lower == "include" || lower == "substring" {
        "contains"
      } else if lower == "startswith" || lower == "prefix" {
        "starts_with"
      } else if lower == "endswith" || lower == "suffix" {
        "ends_with"
      } else if lower == "glob" || lower == "wildcard" {
        "glob"
      } else if lower == "regex" || lower == "re" {
        "regex"
      } else {
        "exact"
      }
    }
    None =>
      if pattern.length() >= 2 &&
        pattern.has_prefix("/") &&
        pattern.has_suffix("/") {
        "regex"
      } else if pattern.contains_char('*') || pattern.contains_char('?') {
        "glob"
      } else {
        "exact"
      }
  }
}

///|
fn resolve_response_stage(stage : String?) -> String {
  match stage {
    Some(value) => {
      let lower = value.to_lower()
      if lower == "complete" || lower == "completed" {
        "completed"
      } else {
        "started"
      }
    }
    None => "started"
  }
}

///|
fn url_matches(url : String, pattern : String, match_mode : String) -> Bool {
  match match_mode {
    "contains" => url.contains(pattern)
    "starts_with" => url.has_prefix(pattern)
    "ends_with" => url.has_suffix(pattern)
    "glob" => glob_match(url, pattern)
    "regex" => regex_match(url, normalize_regex_pattern(pattern))
    _ => url == pattern
  }
}

///|
fn normalize_regex_pattern(pattern : String) -> String {
  if pattern.length() >= 2 && pattern.has_prefix("/") && pattern.has_suffix("/") {
    pattern[1:pattern.length() - 1].to_owned()
  } else {
    pattern
  }
}

///|
fn glob_match(text : String, pattern : String) -> Bool {
  let text_chars = text.to_array()
  let pattern_chars = pattern.to_array()
  let mut ti = 0
  let mut pi = 0
  let mut star = -1
  let mut match_index = 0
  let tlen = text_chars.length()
  let plen = pattern_chars.length()
  while ti < tlen {
    if pi < plen &&
      (pattern_chars[pi] == '?' || pattern_chars[pi] == text_chars[ti]) {
      ti = ti + 1
      pi = pi + 1
      continue
    }
    if pi < plen && pattern_chars[pi] == '*' {
      star = pi
      match_index = ti
      pi = pi + 1
      continue
    }
    if star >= 0 {
      pi = star + 1
      match_index = match_index + 1
      ti = match_index
      continue
    }
    return false
  }
  while pi < plen && pattern_chars[pi] == '*' {
    pi = pi + 1
  }
  pi == plen
}
