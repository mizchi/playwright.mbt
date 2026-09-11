///|
/// Response/Request/Frame types

///|
fn make_response(url : String) -> Response {
  {
    url_: url,
    status_: 0,
    status_text_: "",
    headers_: Headers::empty(),
    from_cache_: false,
    from_service_worker_: false,
  }
}

///|
/// Get response URL
pub fn Response::url(self : Response) -> String {
  self.url_
}

///|
/// Get response status
pub fn Response::status(self : Response) -> Int {
  self.status_
}

///|
/// Get response status text
pub fn Response::status_text(self : Response) -> String {
  self.status_text_
}

///|
/// Check if response is OK (status 200-299)
pub fn Response::ok(self : Response) -> Bool {
  self.status_ >= 200 && self.status_ <= 299
}

///|
/// Get response headers
pub fn Response::headers(self : Response) -> Headers {
  self.headers_
}

///|
/// Get all response headers
pub async fn Response::all_headers(self : Response) -> Headers {
  consume(self)
  async_noop()
  self.headers_
}

///|
/// Get response body as text
pub async fn Response::text(self : Response) -> String {
  consume(self)
  async_noop()
  ""
}

///|
/// Get response body as JSON
pub async fn Response::json(self : Response) -> Json {
  consume(self)
  async_noop()
  Json::null()
}

///|
/// Get response body as buffer
pub async fn Response::body(self : Response) -> ResponseBody {
  consume(self)
  async_noop()
  ResponseBody::bytes(b"")
}

///|
/// Get request associated with response
pub fn Response::request(self : Response) -> Request {
  { url_: self.url_, method_: "GET", headers_: Headers::empty(), }
}

///|
/// Get frame associated with response
pub fn Response::frame(self : Response) -> Frame {
  { url_: self.url_, name_: "", }
}

///|
/// Check if response was served from cache
pub fn Response::from_cache(self : Response) -> Bool {
  self.from_cache_
}

///|
/// Check if response was served from service worker
pub fn Response::from_service_worker(self : Response) -> Bool {
  self.from_service_worker_
}

///| Request type

///|
/// Get request URL
pub fn Request::url(self : Request) -> String {
  self.url_
}

///|
/// Get request method
pub fn Request::method_(self : Request) -> String {
  self.method_
}

///|
/// Get request headers
pub fn Request::headers(self : Request) -> Headers {
  self.headers_
}

///|
/// Get all request headers
pub async fn Request::all_headers(self : Request) -> Headers {
  consume(self)
  async_noop()
  self.headers_
}

///|
/// Get request post data
pub fn Request::post_data(self : Request) -> String? {
  consume(self)
  None
}

///|
/// Get request post data as JSON
pub fn Request::post_data_json(self : Request) -> Json {
  consume(self)
  Json::null()
}

///|
/// Get resource type
pub fn Request::resource_type(self : Request) -> String {
  consume(self)
  ""
}

///|
/// Check if request is navigation request
pub fn Request::is_navigation_request(self : Request) -> Bool {
  consume(self)
  false
}

///|
/// Get response for this request
pub async fn Request::response(self : Request) -> Response? {
  consume(self)
  async_noop()
  None
}

///| Frame type

///|
/// Get frame URL
pub fn Frame::url(self : Frame) -> String {
  self.url_
}

///|
/// Get frame name
pub fn Frame::name(self : Frame) -> String {
  self.name_
}

///|
/// Get frame title
pub async fn Frame::title(self : Frame) -> String {
  consume(self)
  async_noop()
  ""
}

///|
/// Get frame content
pub async fn Frame::content(self : Frame) -> String {
  consume(self)
  async_noop()
  ""
}

///|
/// Get parent frame
pub fn Frame::parent_frame(self : Frame) -> Frame? {
  consume(self)
  None
}

///|
/// Get child frames
pub fn Frame::child_frames(self : Frame) -> Array[Frame] {
  consume(self)
  []
}

///|
/// Check if frame is detached
pub fn Frame::is_detached(self : Frame) -> Bool {
  consume(self)
  false
}

///|
/// Get locator in frame
pub fn Frame::locator(self : Frame, selector : String) -> Locator {
  consume(self)
  let page = make_dummy_page()
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
/// Navigate frame to URL
pub async fn Frame::goto(
  self : Frame,
  url : String,
  timeout? : Int,
  wait_until? : String,
) -> Response? {
  consume((self, timeout, wait_until))
  async_noop()
  Some(make_response(url))
}

///|
fn make_dummy_page() -> Page {
  let client = @bidi.BidiClient::new(@bidi.Transport::unsupported("frame"))
  let browser_state : BrowserState = {
    kind: Chromium,
    client,
    connected: false,
    contexts: [],
    default_context: None,
  }
  let browser : Browser = { state: Ref(browser_state), }
  let context_state : BrowserContextState = {
    browser,
    user_context: "default",
    pages: [],
  }
  let context : BrowserContext = { state: Ref(context_state), }
  let page_state : PageState = {
    browser,
    context,
    context_id: "",
    url: "about:blank",
    navigation_events: [],
    network_listeners: [],
    request_events: [],
    response_events: [],
    response_completed_events: [],
    console_messages: [],
  }
  { state: Ref(page_state), }
}
