///|
/// JSHandle / ElementHandle types

///|
priv struct JSHandleState {
  client : @bidi.BidiClient
  context_id : String
  value : Json
}

///|
pub struct JSHandle {
  priv state : Ref[JSHandleState]
}

///|
pub struct ElementHandle {
  priv handle : JSHandle
}

///|
pub fn JSHandle::from_json(value : Json) -> JSHandle {
  let state : JSHandleState = { client: noop_client, context_id: "", value, }
  { state: Ref(state), }
}

///|
pub fn JSHandle::from_remote_value(value : Json) -> JSHandle {
  JSHandle::from_json(value)
}

///|
pub fn JSHandle::null() -> JSHandle {
  JSHandle::from_json(Json::null())
}

///|
pub fn JSHandle::raw(self : JSHandle) -> Json {
  self.state.val.value
}

///|
pub fn JSHandle::json_value(self : JSHandle) -> Json {
  remote_value_to_json(self.state.val.value)
}

///|
pub fn JSHandle::is_null(self : JSHandle) -> Bool {
  match self.json_value() {
    Null => true
    _ => false
  }
}

///|
pub fn JSHandle::as_element(self : JSHandle) -> ElementHandle? {
  if self.is_null() {
    None
  } else {
    Some(ElementHandle::from_handle(self))
  }
}

///|
pub async fn JSHandle::dispose(self : JSHandle) -> Unit {
  consume(self)
  async_noop()
}

///|
pub async fn JSHandle::evaluate(
  self : JSHandle,
  page_function : String,
  arg? : Json,
) -> Json {
  let state = self.state.val
  if state.context_id.is_empty() {
    return Json::null()
  }
  let args : Array[Json] = [state.value]
  match arg {
    Some(value) => args.push(json_to_remote_value(value))
    None => ()
  }
  let result = state.client.script_call_function(
    page_function,
    state.context_id,
    arguments=args,
  )
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
pub async fn JSHandle::evaluate_handle(
  self : JSHandle,
  page_function : String,
  arg? : Json,
) -> JSHandle {
  let state = self.state.val
  if state.context_id.is_empty() {
    return JSHandle::null()
  }
  let args : Array[Json] = [state.value]
  match arg {
    Some(value) => args.push(json_to_remote_value(value))
    None => ()
  }
  let result = state.client.script_call_function(
    page_function,
    state.context_id,
    arguments=args,
  )
  match result {
    Ok(json) =>
      match json_get_object(json, "result") {
        Some(value) =>
          JSHandle::from_context(state.client, state.context_id, value)
        None =>
          JSHandle::from_context(state.client, state.context_id, Json::null())
      }
    Err(_) => JSHandle::null()
  }
}

///|
pub fn ElementHandle::from_handle(handle : JSHandle) -> ElementHandle {
  { handle, }
}

///|
pub fn ElementHandle::as_js_handle(self : ElementHandle) -> JSHandle {
  self.handle
}

///|
pub fn ElementHandle::json_value(self : ElementHandle) -> Json {
  self.handle.json_value()
}

///|
pub async fn ElementHandle::dispose(self : ElementHandle) -> Unit {
  self.handle.dispose()
}

///|
pub async fn ElementHandle::evaluate(
  self : ElementHandle,
  page_function : String,
  arg? : Json,
) -> Json {
  match arg {
    Some(value) => self.handle.evaluate(page_function, arg=value)
    None => self.handle.evaluate(page_function)
  }
}

///|
pub async fn ElementHandle::evaluate_handle(
  self : ElementHandle,
  page_function : String,
  arg? : Json,
) -> JSHandle {
  match arg {
    Some(value) => self.handle.evaluate_handle(page_function, arg=value)
    None => self.handle.evaluate_handle(page_function)
  }
}

///|
fn JSHandle::from_context(
  client : @bidi.BidiClient,
  context_id : String,
  value : Json,
) -> JSHandle {
  let state : JSHandleState = { client, context_id, value, }
  { state: Ref(state), }
}

///|
fn JSHandle::from_page(page : Page, value : Json) -> JSHandle {
  let state = page.state.val
  JSHandle::from_context(
    state.browser.state.val.client,
    state.context_id,
    value,
  )
}
