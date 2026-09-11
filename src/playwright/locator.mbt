///|
/// Locator methods

///|
/// Filter locator
pub fn Locator::filter(
  self : Locator,
  has? : Locator,
  has_not? : Locator,
  has_text? : String,
  has_not_text? : String,
) -> Locator {
  consume((has, has_not, has_not_text))
  let state = self.state.val
  let selector = state.selector
  let new_has_text = match has_text {
    Some(text) => Some(text)
    None => state.has_text
  }
  let new_has_text_exact = state.has_text_exact
  let new_has_not_text = match has_not_text {
    Some(text) => Some(text)
    None => state.has_not_text
  }
  let new_state : LocatorState = {
    page: state.page,
    selector,
    index: state.index,
    has_text: new_has_text,
    has_text_exact: new_has_text_exact,
    has_not_text: new_has_not_text,
    label_text: state.label_text,
    label_text_exact: state.label_text_exact,
    label_scope_selector: state.label_scope_selector,
  }
  { state: { val: new_state, }, }
}

///|
/// Get first element
pub fn Locator::first(self : Locator) -> Locator {
  let state = self.state.val
  let new_state : LocatorState = {
    page: state.page,
    selector: state.selector,
    index: Some(0),
    has_text: state.has_text,
    has_text_exact: state.has_text_exact,
    has_not_text: state.has_not_text,
    label_text: state.label_text,
    label_text_exact: state.label_text_exact,
    label_scope_selector: state.label_scope_selector,
  }
  { state: { val: new_state, }, }
}

///|
/// Get last element
pub fn Locator::last(self : Locator) -> Locator {
  let state = self.state.val
  let new_state : LocatorState = {
    page: state.page,
    selector: state.selector,
    index: Some(-1),
    has_text: state.has_text,
    has_text_exact: state.has_text_exact,
    has_not_text: state.has_not_text,
    label_text: state.label_text,
    label_text_exact: state.label_text_exact,
    label_scope_selector: state.label_scope_selector,
  }
  { state: { val: new_state, }, }
}

///|
/// Get nth element (0-indexed)
pub fn Locator::nth(self : Locator, index : Int) -> Locator {
  let state = self.state.val
  let new_state : LocatorState = {
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
  { state: { val: new_state, }, }
}

///|
/// Get locator within this locator
pub fn Locator::locator(self : Locator, selector : String) -> Locator {
  let state = self.state.val
  let combined = state.selector + " " + selector
  let new_state : LocatorState = {
    page: state.page,
    selector: combined,
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: None,
    label_text: None,
    label_text_exact: false,
    label_scope_selector: None,
  }
  { state: { val: new_state, }, }
}

///|
/// Get by role within this locator
pub fn Locator::get_by_role(
  self : Locator,
  role : String,
  name? : String,
  exact? : Bool,
) -> Locator {
  consume(exact)
  let selector = self.state.val.selector +
    " [role=" +
    js_string_literal(role) +
    "]"
  let base = Locator::from_selector(self.state.val.page, selector)
  match name {
    Some(text) => base.get_by_text(text, exact?)
    None => base
  }
}

///|
/// Get by text within this locator
pub fn Locator::get_by_text(
  self : Locator,
  text : String,
  exact? : Bool,
) -> Locator {
  let exact_flag = match exact {
    Some(true) => true
    _ => false
  }
  let state = self.state.val
  let new_state : LocatorState = {
    page: state.page,
    selector: state.selector,
    index: state.index,
    has_text: Some(text),
    has_text_exact: exact_flag,
    has_not_text: state.has_not_text,
    label_text: state.label_text,
    label_text_exact: state.label_text_exact,
    label_scope_selector: state.label_scope_selector,
  }
  { state: { val: new_state, }, }
}

///|
/// Get by label within this locator
pub fn Locator::get_by_label(
  self : Locator,
  text : String,
  exact? : Bool,
) -> Locator {
  let exact_flag = match exact {
    Some(true) => true
    _ => false
  }
  let state = self.state.val
  let selector = state.selector + " label"
  let new_state : LocatorState = {
    page: state.page,
    selector,
    index: None,
    has_text: None,
    has_text_exact: false,
    has_not_text: state.has_not_text,
    label_text: Some(text),
    label_text_exact: exact_flag,
    label_scope_selector: Some(state.selector),
  }
  { state: { val: new_state, }, }
}

///|
/// Get by placeholder within this locator
pub fn Locator::get_by_placeholder(
  self : Locator,
  text : String,
  exact? : Bool,
) -> Locator {
  consume(exact)
  self.locator("[placeholder=" + js_string_literal(text) + "]")
}

///|
/// Get by test ID within this locator
pub fn Locator::get_by_test_id(self : Locator, testId : String) -> Locator {
  self.locator("[data-testid=" + js_string_literal(testId) + "]")
}

///| Action Methods

///|
/// Click element
pub async fn Locator::click(
  self : Locator,
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
  let expr = self.element_expression() +
    " && " +
    self.element_expression() +
    ".click()"
  let _ = self.page_eval(expr)
}

///|
/// Double click element
pub async fn Locator::dblclick(
  self : Locator,
  timeout? : Int,
  force? : Bool,
) -> Unit {
  consume((timeout, force))
  let expr = "(() => { const el = " +
    self.element_expression() +
    "; if (!el) return; const ev = new MouseEvent('dblclick',{bubbles:true}); el.dispatchEvent(ev); })()"
  let _ = self.page_eval(expr)
}

///|
/// Fill input
pub async fn Locator::fill(
  self : Locator,
  value : String,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  // Pass selector and value via callFunction arguments (avoids escaping issues)
  let selector = self.state.val.selector
  let page = self.state.val.page
  let client = page.state.val.browser.state.val.client
  let ctx = page.state.val.context_id
  let args = [
    json_to_remote_value(Json::string(selector)),
    json_to_remote_value(Json::string(value)),
  ]
  let result = client.script_call_function(
    "(sel, val) => { const el = document.querySelector(sel); if (!el) return false; el.focus(); el.value = val; el.dispatchEvent(new InputEvent('input',{bubbles:true,data:val,inputType:'insertText'})); el.dispatchEvent(new Event('change',{bubbles:true})); return true; }",
    ctx,
    arguments=args,
  )
  consume(result)
}

///|
/// Clear input
pub async fn Locator::clear(
  self : Locator,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  self.fill("")
}

///|
/// Type text (keystroke by keystroke)
pub async fn Locator::type_(
  self : Locator,
  text : String,
  delay? : Int,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((delay, no_wait_after, timeout))
  let expr = "(() => { const el = " +
    self.element_expression() +
    "; if (!el) return; el.value = (el.value || '') + " +
    js_string_literal(text) +
    "; el.dispatchEvent(new Event('input',{bubbles:true})); })()"
  let _ = self.page_eval(expr)
}

///|
/// Press key
pub async fn Locator::press(
  self : Locator,
  key : String,
  delay? : Int,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((delay, no_wait_after, timeout))
  let expr = "(() => { const el = " +
    self.element_expression() +
    "; if (!el) return; const ev = new KeyboardEvent('keydown',{key:" +
    js_string_literal(key) +
    ",bubbles:true}); el.dispatchEvent(ev); })()"
  let _ = self.page_eval(expr)
}

///|
/// Check checkbox
pub async fn Locator::check(
  self : Locator,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  let expr = "(() => { const el = " +
    self.element_expression() +
    "; if (!el) return; el.checked = true; el.dispatchEvent(new Event('change',{bubbles:true})); })()"
  let _ = self.page_eval(expr)
}

///|
/// Uncheck checkbox
pub async fn Locator::uncheck(
  self : Locator,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  let expr = "(() => { const el = " +
    self.element_expression() +
    "; if (!el) return; el.checked = false; el.dispatchEvent(new Event('change',{bubbles:true})); })()"
  let _ = self.page_eval(expr)
}

///|
/// Set checkbox state
pub async fn Locator::set_checked(
  self : Locator,
  checked : Bool,
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Unit {
  consume((force, no_wait_after, timeout))
  if checked {
    self.check()
  } else {
    self.uncheck()
  }
}

///|
/// Select option(s) in dropdown
pub async fn Locator::select_option(
  self : Locator,
  values : Array[SelectOption],
  force? : Bool,
  no_wait_after? : Bool,
  timeout? : Int,
) -> Array[String] {
  consume((self, values, force, no_wait_after, timeout))
  async_noop()
  []
}

///|
/// Hover over element
pub async fn Locator::hover(
  self : Locator,
  force? : Bool,
  modifiers? : Array[String],
  position? : (Double, Double),
  timeout? : Int,
  trial? : Bool,
) -> Unit {
  consume((force, modifiers, position, timeout, trial))
  let expr = "(() => { const el = " +
    self.element_expression() +
    "; if (!el) return; const ev = new MouseEvent('mouseover',{bubbles:true}); el.dispatchEvent(ev); })()"
  let _ = self.page_eval(expr)
}

///|
/// Focus element
pub async fn Locator::focus(self : Locator, timeout? : Int) -> Unit {
  consume(timeout)
  let expr = self.element_expression() +
    " && " +
    self.element_expression() +
    ".focus()"
  let _ = self.page_eval(expr)
}

///|
/// Blur element
pub async fn Locator::blur(self : Locator, timeout? : Int) -> Unit {
  consume(timeout)
  let expr = self.element_expression() +
    " && " +
    self.element_expression() +
    ".blur()"
  let _ = self.page_eval(expr)
}

///|
/// Scroll element into view
pub async fn Locator::scroll_into_view_if_needed(
  self : Locator,
  timeout? : Int,
) -> Unit {
  consume(timeout)
  let expr = self.element_expression() +
    " && " +
    self.element_expression() +
    ".scrollIntoView()"
  let _ = self.page_eval(expr)
}

///| Property Methods

///|
/// Get inner text
pub async fn Locator::inner_text(self : Locator, timeout? : Int) -> String {
  consume(timeout)
  match self.eval_string(self.element_expression() + "?.innerText") {
    Some(v) => v
    None => ""
  }
}

///|
/// Get inner HTML
pub async fn Locator::inner_html(self : Locator, timeout? : Int) -> String {
  consume(timeout)
  match self.eval_string(self.element_expression() + "?.innerHTML") {
    Some(v) => v
    None => ""
  }
}

///|
/// Get text content
pub async fn Locator::text_content(self : Locator, timeout? : Int) -> String? {
  consume(timeout)
  self.eval_string(self.element_expression() + "?.textContent")
}

///|
/// Get all text contents
pub async fn Locator::all_text_contents(self : Locator) -> Array[String] {
  consume(self)
  async_noop()
  []
}

///|
/// Get all inner texts
pub async fn Locator::all_inner_texts(self : Locator) -> Array[String] {
  consume(self)
  async_noop()
  []
}

///|
/// Get attribute
pub async fn Locator::get_attribute(
  self : Locator,
  name : String,
  timeout? : Int,
) -> String? {
  consume(timeout)
  self.eval_string(
    self.element_expression() +
    "?.getAttribute(" +
    js_string_literal(name) +
    ")",
  )
}

///|
/// Get input value
pub async fn Locator::input_value(self : Locator, timeout? : Int) -> String {
  consume(timeout)
  match self.eval_string(self.element_expression() + "?.value") {
    Some(v) => v
    None => ""
  }
}

///|
/// Check if element is visible
pub async fn Locator::is_visible(self : Locator, timeout? : Int) -> Bool {
  consume(timeout)
  match self.eval_bool(self.element_expression() + "?.offsetParent !== null") {
    Some(v) => v
    None => false
  }
}

///|
/// Check if element is hidden
pub async fn Locator::is_hidden(self : Locator, timeout? : Int) -> Bool {
  consume(timeout)
  match self.eval_bool(self.element_expression() + "?.offsetParent === null") {
    Some(v) => v
    None => true
  }
}

///|
/// Check if element is enabled
pub async fn Locator::is_enabled(self : Locator, timeout? : Int) -> Bool {
  consume(timeout)
  match self.eval_bool(self.element_expression() + "?.disabled === false") {
    Some(v) => v
    None => false
  }
}

///|
/// Check if element is disabled
pub async fn Locator::is_disabled(self : Locator, timeout? : Int) -> Bool {
  consume(timeout)
  match self.eval_bool(self.element_expression() + "?.disabled === true") {
    Some(v) => v
    None => false
  }
}

///|
/// Check if element is editable
pub async fn Locator::is_editable(self : Locator, timeout? : Int) -> Bool {
  consume(timeout)
  match self.eval_bool(self.element_expression() + "?.readOnly === false") {
    Some(v) => v
    None => false
  }
}

///|
/// Check if checkbox is checked
pub async fn Locator::is_checked(self : Locator, timeout? : Int) -> Bool {
  consume(timeout)
  match self.eval_bool(self.element_expression() + "?.checked === true") {
    Some(v) => v
    None => false
  }
}

///|
/// Get element count
pub async fn Locator::count(self : Locator) -> Int {
  consume(self)
  async_noop()
  0
}

///|
/// Get bounding box
pub async fn Locator::bounding_box(
  self : Locator,
  timeout? : Int,
) -> BoundingBox? {
  consume(timeout)
  let expr = "(() => { const el = " +
    self.element_expression() +
    "; if (!el || !el.getBoundingClientRect) return null; const r = el.getBoundingClientRect(); return JSON.stringify({x:r.x,y:r.y,width:r.width,height:r.height}); })()"
  match self.state.val.page.evaluate(expr) {
    String(payload) =>
      BoundingBox::from_json(@json.parse(payload) catch { _ => Json::null() })
    _ => None
  }
}

///| Wait Methods

///|
/// Wait for element to be visible/hidden/attached/detached
pub async fn Locator::wait_for(
  self : Locator,
  state? : String,
  timeout? : Int,
) -> Unit {
  let page = self.state.val.page
  let selector = self.state.val.selector
  match (state, timeout) {
    (Some(s), Some(t)) => {
      let _ = page.wait_for_selector(selector, state=s, timeout=t)
    }
    (Some(s), None) => {
      let _ = page.wait_for_selector(selector, state=s)
    }
    (None, Some(t)) => {
      let _ = page.wait_for_selector(selector, timeout=t)
    }
    (None, None) => {
      let _ = page.wait_for_selector(selector)
    }
  }
}

///| Screenshot

///|
/// Take screenshot of element
pub async fn Locator::screenshot(
  self : Locator,
  path? : String,
  type_? : String,
  quality? : Int,
  omit_background? : Bool,
  timeout? : Int,
  scale? : String,
) -> ResponseBody {
  consume((self, path, type_, quality, omit_background, timeout, scale))
  async_noop()
  ResponseBody::bytes(b"")
}

///| Evaluate

///|
/// Evaluate JavaScript in element context
pub async fn Locator::evaluate(
  self : Locator,
  page_function : String,
  arg? : Json,
  timeout? : Int,
) -> Json {
  consume(timeout)
  match arg {
    Some(value) => self.state.val.page.evaluate(page_function, arg=value)
    None => self.state.val.page.evaluate(page_function)
  }
}

///|
/// Evaluate all matching elements
pub async fn Locator::evaluate_all(
  self : Locator,
  page_function : String,
  arg? : Json,
) -> Json {
  match arg {
    Some(value) => self.state.val.page.evaluate(page_function, arg=value)
    None => self.state.val.page.evaluate(page_function)
  }
}

///|
fn Locator::from_selector(page : Page, selector : String) -> Locator {
  let state : LocatorState = {
    page,
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
fn Locator::element_expression(self : Locator) -> String {
  let state = self.state.val
  let selector = js_string_literal(state.selector)
  let not_text_literal = match state.has_not_text {
    Some(text) => js_string_literal(text)
    None => "null"
  }
  match state.label_text {
    Some(text) => {
      let text_literal = js_string_literal(text)
      let exact_flag = if state.label_text_exact { "true" } else { "false" }
      let scope_literal = match state.label_scope_selector {
        Some(value) => js_string_literal(value)
        None => "null"
      }
      let index_expr = match state.index {
        Some(i) =>
          if i < 0 {
            "return matches.length === 0 ? null : matches[matches.length - 1];"
          } else {
            "return matches.length <= " +
            i.to_string() +
            " ? null : matches[" +
            i.to_string() +
            "];"
          }
        None => "return matches.length === 0 ? null : matches[0];"
      }
      "(function(){ const labels = Array.from(document.querySelectorAll(" +
      selector +
      ")); const txt = " +
      text_literal +
      "; const exact = " +
      exact_flag +
      "; const notTxt = " +
      not_text_literal +
      "; const scopeSelector = " +
      scope_literal +
      "; const scopes = scopeSelector ? Array.from(document.querySelectorAll(scopeSelector)) : []; const inScope = (el) => { if (!scopeSelector) return true; return scopes.some(s => s.contains(el)); }; const norm = (s) => (s || '').replace(/[\\u200B\\u200C\\u200D\\uFEFF]/g,'').replace(/[\\u00a0\\u1680\\u2000-\\u200A\\u202F\\u205F\\u3000]/g,' ').replace(/\\s+/g,' ').trim(); const query = norm(txt); const notQuery = notTxt ? norm(notTxt) : null; const textMatch = (t) => { const n = norm(t); return exact ? n === query : n.includes(query); }; const labelText = (el) => { const t = norm((el.innerText || el.textContent || '')); return t.length > 0 ? t : null; }; const labelledByText = (el) => { const value = el.getAttribute && el.getAttribute('aria-labelledby'); if (!value) return null; const raw = value.split(/\\s+/).filter(Boolean); const ids = []; for (const id of raw) { if (ids.indexOf(id) >= 0) continue; ids.push(id); } const nodes = []; for (const id of ids) { const node = document.getElementById(id); if (node) nodes.push(node); } nodes.sort((a,b) => { if (a === b) return 0; const pos = a.compareDocumentPosition(b); if (pos & Node.DOCUMENT_POSITION_FOLLOWING) return -1; if (pos & Node.DOCUMENT_POSITION_PRECEDING) return 1; return 0; }); const parts = []; for (const node of nodes) { const lt = labelText(node); if (lt) parts.push(lt); } if (parts.length === 0) return null; return norm(parts.join(' ')); }; const ariaLabelText = (el) => { const value = el.getAttribute && el.getAttribute('aria-label'); if (!value) return null; const t = norm(value); return t.length > 0 ? t : null; }; const labelTextFor = (el) => { const parts = []; const id = el.getAttribute && el.getAttribute('id'); if (id) { const rel = Array.from(document.querySelectorAll('label[for=\"' + id + '\"]')); for (const label of rel) { const t = labelText(label); if (t) parts.push(t); } } if (parts.length > 0) return norm(parts.join(' ')); let parent = el.parentElement; while (parent) { if (parent.tagName === 'LABEL') { const t = labelText(parent); if (t) return t; break; } parent = parent.parentElement; } return null; }; const accessibleName = (el) => { const by = labelledByText(el); if (by) return by; const aria = ariaLabelText(el); if (aria) return aria; const lab = labelTextFor(el); if (lab) return lab; return null; }; const labelScore = (el) => { const by = el.getAttribute && el.getAttribute('aria-labelledby'); if (by && by.trim().length > 0) return 0; const id = el.getAttribute && el.getAttribute('id'); if (id) { const rel = document.querySelector('label[for=\"' + id + '\"]'); if (rel) return 1; } let parent = el.parentElement; while (parent) { if (parent.tagName === 'LABEL') return 2; parent = parent.parentElement; } const aria = el.getAttribute && el.getAttribute('aria-label'); if (aria && aria.trim().length > 0) return 3; return 4; }; const is_visible = (el) => { if (!el || el.nodeType !== 1) return false; let cur = el; while (cur) { if (cur.hidden) return false; const ariaHidden = cur.getAttribute && cur.getAttribute('aria-hidden'); if (ariaHidden === 'true') return false; const style = (cur.ownerDocument && cur.ownerDocument.defaultView) ? cur.ownerDocument.defaultView.getComputedStyle(cur) : null; if (style) { if (style.display === 'none' || style.visibility === 'hidden' || (style.visibility === 'collapse' && (cur.tagName === 'TABLE' || cur.tagName === 'TBODY' || cur.tagName === 'TR' || cur.tagName === 'TD' || cur.tagName === 'TH')) || style.contentVisibility === 'hidden') return false; const op = parseFloat(style.opacity || '1'); if (op == 0) return false; } cur = cur.parentElement; } if (el.getClientRects && el.getClientRects().length === 0) return false; if (el.getBoundingClientRect) { const r = el.getBoundingClientRect(); if (r && (r.width <= 0 || r.height <= 0)) return false; } return true; }; const nodeDepth = (n) => { let d = 0; let cur = n; while (cur) { d = d + 1; cur = cur.parentNode; } return d; }; const domDistance = (a, b) => { if (!a || !b) return 1e9; let da = nodeDepth(a); let db = nodeDepth(b); let pa = a; let pb = b; while (da > db) { pa = pa.parentNode; da = da - 1; } while (db > da) { pb = pb.parentNode; db = db - 1; } while (pa && pb && pa !== pb) { pa = pa.parentNode; pb = pb.parentNode; } if (!pa || !pb) return 1e9; const lca = pa; return (nodeDepth(a) - nodeDepth(lca)) + (nodeDepth(b) - nodeDepth(lca)); }; const labelNodesFor = (el) => { const nodes = []; const labelledBy = el.getAttribute && el.getAttribute('aria-labelledby'); if (labelledBy) { const raw = labelledBy.split(/\\s+/).filter(Boolean); const ids = []; for (const id of raw) { if (ids.indexOf(id) >= 0) continue; ids.push(id); } for (const id of ids) { const node = document.getElementById(id); if (node) nodes.push(node); } } const id = el.getAttribute && el.getAttribute('id'); if (id) { const rel = Array.from(document.querySelectorAll('label[for=\"' + id + '\"]')); for (const label of rel) nodes.push(label); } let parent = el.parentElement; while (parent) { if (parent.tagName === 'LABEL') { nodes.push(parent); break; } parent = parent.parentElement; } return nodes; }; const labelDistance = (el) => { const nodes = labelNodesFor(el); if (nodes.length === 0) return 1e9; let best = 1e9; for (const node of nodes) { if (node.tagName === 'LABEL') { const forId = node.getAttribute && node.getAttribute('for'); const id = el.getAttribute && el.getAttribute('id'); if (forId && id && forId === id) return 0; if (node.contains && node.contains(el)) return 1; } const d = domDistance(el, node); if (d < best) best = d; } return best; }; let matches = []; const candidates = Array.from(document.querySelectorAll('input, textarea, select, button, [aria-labelledby], [aria-label]')); for (const el of candidates) { if (!inScope(el)) continue; const name = accessibleName(el); if (!name) continue; if (notQuery && name.includes(notQuery)) continue; if (!textMatch(name)) continue; matches.push(el); } if (matches.length === 0) { for (const label of labels) { if (!inScope(label)) continue; const t = labelText(label); if (!t) continue; if (notQuery && t.includes(notQuery)) continue; if (!textMatch(t)) continue; let control = null; const forId = label.getAttribute && label.getAttribute('for'); if (forId) { const target = document.getElementById(forId); if (target) control = target; } if (!control && label.querySelector) { control = label.querySelector('input, textarea, select, button'); } if (!control) control = label; if (!inScope(control)) continue; matches.push(control); } } if (matches.length > 1) { const visible = matches.filter(is_visible); if (visible.length > 0) matches = visible; matches.sort((a, b) => { const da = labelDistance(a); const db = labelDistance(b); if (da < db) return -1; if (da > db) return 1; const sa = labelScore(a); const sb = labelScore(b); if (sa < sb) return -1; if (sa > sb) return 1; if (a === b) return 0; const pos = a.compareDocumentPosition(b); if (pos & Node.DOCUMENT_POSITION_FOLLOWING) return -1; if (pos & Node.DOCUMENT_POSITION_PRECEDING) return 1; return 0; }); } const pick = (function(){ " +
      index_expr +
      " })(); return pick; })()"
    }
    None =>
      match state.has_text {
        Some(text) => {
          let text_literal = js_string_literal(text)
          let exact_flag = if state.has_text_exact { "true" } else { "false" }
          let index_expr = match state.index {
            Some(i) =>
              if i < 0 {
                "return matches.length === 0 ? null : matches[matches.length - 1];"
              } else {
                "return matches.length <= " +
                i.to_string() +
                " ? null : matches[" +
                i.to_string() +
                "];"
              }
            None => "return matches.length === 0 ? null : matches[0];"
          }
          "(function(){ const els = Array.from(document.querySelectorAll(" +
          selector +
          ")); const txt = " +
          text_literal +
          "; const exact = " +
          exact_flag +
          "; const notTxt = " +
          not_text_literal +
          "; const matches = els.filter(el => { const t = (el.textContent || '').trim(); if (notTxt && t.includes(notTxt)) return false; return exact ? t === txt : t.includes(txt); }); " +
          index_expr +
          " })()"
        }
        None =>
          match state.has_not_text {
            Some(_) => {
              let index_expr = match state.index {
                Some(i) =>
                  if i < 0 {
                    "return matches.length === 0 ? null : matches[matches.length - 1];"
                  } else {
                    "return matches.length <= " +
                    i.to_string() +
                    " ? null : matches[" +
                    i.to_string() +
                    "];"
                  }
                None => "return matches.length === 0 ? null : matches[0];"
              }
              "(function(){ const els = Array.from(document.querySelectorAll(" +
              selector +
              ")); const notTxt = " +
              not_text_literal +
              "; const matches = els.filter(el => { const t = (el.textContent || '').trim(); if (notTxt && t.includes(notTxt)) return false; return true; }); " +
              index_expr +
              " })()"
            }
            None =>
              match state.index {
                Some(i) =>
                  if i < 0 {
                    "(function(){ const els = document.querySelectorAll(" +
                    selector +
                    "); return els.length === 0 ? null : els[els.length - 1]; })()"
                  } else {
                    "(document.querySelectorAll(" +
                    selector +
                    ")[" +
                    i.to_string() +
                    "] || null)"
                  }
                None => "document.querySelector(" + selector + ")"
              }
          }
      }
  }
}

///|
async fn Locator::page_eval(self : Locator, expression : String) -> Unit {
  let page = self.state.val.page
  let result = page.evaluate(expression)
  consume(result)
}

///|
async fn Locator::eval_string(self : Locator, expression : String) -> String? {
  let page_state = self.state.val.page.state.val
  let result = page_state.browser.state.val.client.script_evaluate(
    expression,
    page_state.context_id,
  )
  match result {
    Ok(json) =>
      match json_get_object(json, "result") {
        Some(value) =>
          match remote_value_to_json(value) {
            String(text) => Some(text)
            _ => None
          }
        None => None
      }
    Err(_) => None
  }
}

///|
async fn Locator::eval_bool(self : Locator, expression : String) -> Bool? {
  let page_state = self.state.val.page.state.val
  let result = page_state.browser.state.val.client.script_evaluate(
    expression,
    page_state.context_id,
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
