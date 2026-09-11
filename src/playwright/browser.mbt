///|
/// Browser methods

///|
pub async fn Browser::close(self : Browser) -> Unit {
  let state = self.state.val
  state.connected = false
  match state.client.session_end() {
    Ok(_) => ()
    Err(_) => ()
  }
  state.client.close() |> ignore
  // Kill spawned browser processes
  ffi_kill_browser_processes()
}

///|
/// Close browser with error callback (for use with defer)
/// Note: This initiates close but doesn't wait for completion
pub fn Browser::close_with_error_callback(
  self : Browser,
  on_error : (Error) -> Unit,
) -> Unit {
  let _ = on_error
  self.state.val.connected = false
}

///|
/// Create new browser context
pub async fn Browser::new_context(
  self : Browser,
  viewport? : (Int, Int),
  user_agent? : String,
  locale? : String,
  timezone_id? : String,
  geolocation? : (Double, Double),
  permissions? : Array[String],
  color_scheme? : String,
  reduced_motion? : String,
  forced_colors? : String,
  accept_downloads? : Bool,
  ignore_https_errors? : Bool,
  javascript_enabled? : Bool,
  bypass_csp? : Bool,
  offline? : Bool,
  device_scale_factor? : Double,
  is_mobile? : Bool,
  has_touch? : Bool,
) -> BrowserContext {
  let _ = viewport
  let _ = user_agent
  let _ = locale
  let _ = timezone_id
  let _ = geolocation
  let _ = permissions
  let _ = color_scheme
  let _ = reduced_motion
  let _ = forced_colors
  let _ = accept_downloads
  let _ = ignore_https_errors
  let _ = javascript_enabled
  let _ = bypass_csp
  let _ = offline
  let _ = device_scale_factor
  let _ = is_mobile
  let _ = has_touch
  let state = self.state.val
  let user_context = match state.client.browser_create_user_context() {
    Ok(id) => id
    Err(_) => "default"
  }
  let ctx_state : BrowserContextState = {
    browser: self,
    user_context,
    pages: [],
  }
  let ctx : BrowserContext = { state: Ref(ctx_state), }
  state.contexts.push(ctx.state)
  ctx
}

///|
/// Create new page (with default context)
pub async fn Browser::new_page(
  self : Browser,
  viewport? : (Int, Int),
  user_agent? : String,
  locale? : String,
  timezone_id? : String,
  ignore_https_errors? : Bool,
  javascript_enabled? : Bool,
  bypass_csp? : Bool,
  offline? : Bool,
  color_scheme? : String,
  device_scale_factor? : Double,
  is_mobile? : Bool,
  has_touch? : Bool,
) -> Page {
  let _ = viewport
  let _ = user_agent
  let _ = locale
  let _ = timezone_id
  let _ = ignore_https_errors
  let _ = javascript_enabled
  let _ = bypass_csp
  let _ = offline
  let _ = color_scheme
  let _ = device_scale_factor
  let _ = is_mobile
  let _ = has_touch
  let ctx = self.ensure_default_context()
  ctx.new_page()
}

///|
/// Get all contexts
pub fn Browser::contexts(self : Browser) -> Array[BrowserContext] {
  let list : Array[BrowserContext] = []
  for ctx_state in self.state.val.contexts {
    let ctx : BrowserContext = { state: ctx_state, }
    list.push(ctx)
  }
  list
}

///|
/// Check if browser is connected
pub fn Browser::is_connected(self : Browser) -> Bool {
  self.state.val.connected
}

///|
/// Get browser version
pub fn Browser::version(self : Browser) -> String {
  match self.state.val.kind {
    Chromium => "bidi-chromium"
    Firefox => "bidi-firefox"
    WebKit => "bidi-webkit"
  }
}

///|
fn Browser::ensure_default_context(self : Browser) -> BrowserContext {
  let state = self.state.val
  match state.default_context {
    Some(ctx) => ctx.val
    None => {
      let ctx_state : BrowserContextState = {
        browser: self,
        user_context: "default",
        pages: [],
      }
      let ctx : BrowserContext = { state: Ref(ctx_state), }
      state.default_context = Some(Ref(ctx))
      ctx
    }
  }
}
