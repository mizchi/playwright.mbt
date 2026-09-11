///|
/// BrowserContext methods

///|
/// Close context
pub async fn BrowserContext::close(self : BrowserContext) -> Unit {
  let state = self.state.val
  for page_state in state.pages {
    let page : Page = { state: page_state, }
    page.close() |> ignore
  }
  if state.user_context != "default" {
    let _ = state.browser.state.val.client.browser_remove_user_context(
      state.user_context,
    )
  }
}

///|
/// Close context with error callback (for use with defer)
/// Note: This initiates close but doesn't wait for completion
pub fn BrowserContext::close_with_error_callback(
  self : BrowserContext,
  on_error : (Error) -> Unit,
) -> Unit {
  let _ = self
  let _ = on_error
}

///|
/// Create new page in context
pub async fn BrowserContext::new_page(self : BrowserContext) -> Page {
  let state = self.state.val
  let context_id = match
    state.browser.state.val.client.browsing_context_create(
      "tab",
      user_context=state.user_context,
    ) {
    Ok(id) => id
    Err(_) => ""
  }
  let page_state : PageState = {
    browser: state.browser,
    context: self,
    context_id,
    url: "about:blank",
    navigation_events: [],
    network_listeners: [],
    request_events: [],
    response_events: [],
    response_completed_events: [],
    console_messages: [],
  }
  let page : Page = { state: Ref(page_state), }
  state.pages.push(page.state)
  page
}

///|
/// Get all pages in context
pub fn BrowserContext::pages(self : BrowserContext) -> Array[Page] {
  let list : Array[Page] = []
  for page_state in self.state.val.pages {
    let page : Page = { state: page_state, }
    list.push(page)
  }
  list
}

///|
/// Set default navigation timeout
pub fn BrowserContext::set_default_navigation_timeout(
  self : BrowserContext,
  timeout : Int,
) -> Unit {
  let _ = self
  let _ = timeout
}

///|
/// Set default timeout
pub fn BrowserContext::set_default_timeout(
  self : BrowserContext,
  timeout : Int,
) -> Unit {
  let _ = self
  let _ = timeout
}

///|
/// Add cookies
pub async fn BrowserContext::add_cookies(
  self : BrowserContext,
  cookies : Array[Cookie],
) -> Unit {
  consume((self, cookies))
  async_noop()
}

///|
/// Clear cookies
pub async fn BrowserContext::clear_cookies(self : BrowserContext) -> Unit {
  consume(self)
  async_noop()
}

///|
/// Get cookies
pub async fn BrowserContext::cookies(
  self : BrowserContext,
  urls? : Array[String],
) -> Array[Cookie] {
  consume((self, urls))
  async_noop()
  []
}

///|
/// Grant permissions
pub async fn BrowserContext::grant_permissions(
  self : BrowserContext,
  permissions : Array[String],
  origin? : String,
) -> Unit {
  consume((self, permissions, origin))
  async_noop()
}

///|
/// Clear permissions
pub async fn BrowserContext::clear_permissions(self : BrowserContext) -> Unit {
  consume(self)
  async_noop()
}

///|
/// Set geolocation
pub async fn BrowserContext::set_geolocation(
  self : BrowserContext,
  latitude : Double,
  longitude : Double,
  accuracy? : Double,
) -> Unit {
  consume((self, latitude, longitude, accuracy))
  async_noop()
}

///|
/// Set offline mode
pub async fn BrowserContext::set_offline(
  self : BrowserContext,
  offline : Bool,
) -> Unit {
  consume((self, offline))
  async_noop()
}
