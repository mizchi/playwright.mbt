///|
/// BiDi event routing

///|
fn register_bidi_event_router(state_ref : Ref[BrowserState]) -> Unit {
  let client = state_ref.val.client
  client.on_event(fn(evt : @bidi.BidiEvent) {
    dispatch_bidi_event(state_ref, evt)
  })
}

///|
fn dispatch_bidi_event(
  state_ref : Ref[BrowserState],
  evt : @bidi.BidiEvent,
) -> Unit {
  match evt.event_method {
    "browsingContext.load" =>
      handle_navigation_event(state_ref, "browsingContext.load", evt.params)
    "browsingContext.domContentLoaded" =>
      handle_navigation_event(
        state_ref,
        "browsingContext.domContentLoaded",
        evt.params,
      )
    "network.beforeRequestSent" => handle_network_request(state_ref, evt.params)
    "network.responseStarted" =>
      handle_network_response(state_ref, "started", evt.params)
    "network.responseCompleted" =>
      handle_network_response(state_ref, "completed", evt.params)
    "log.entryAdded" => handle_log_entry(state_ref, evt.params)
    _ => ()
  }
}

///|
fn handle_navigation_event(
  state_ref : Ref[BrowserState],
  event_name : String,
  params : Json,
) -> Unit {
  let context_id = event_context_id(params)
  let url = event_get_string(params, "url")
  match context_id {
    Some(ctx) => {
      let evt : NavigationEvent = { event_name, url: url.unwrap_or(""), }
      match find_page_state(state_ref.val, ctx) {
        Some(page_state) => {
          page_state.val.navigation_events.push(evt)
          match url {
            Some(u) => page_state.val.url = u
            None => ()
          }
        }
        None => ()
      }
    }
    None => ()
  }
}

///|
fn handle_network_request(state_ref : Ref[BrowserState], params : Json) -> Unit {
  let context_id = event_context_id(params)
  match (context_id, event_get_object(params, "request")) {
    (Some(ctx), Some(req_json)) =>
      match request_from_json(req_json) {
        Some(req) =>
          match find_page_state(state_ref.val, ctx) {
            Some(page_state) => {
              page_state.val.request_events.push(req)
              dispatch_network_event(page_state, NetworkEvent::Request(req))
            }
            None => ()
          }
        None => ()
      }
    _ => ()
  }
}

///|
fn handle_network_response(
  state_ref : Ref[BrowserState],
  stage : String,
  params : Json,
) -> Unit {
  let context_id = event_context_id(params)
  match (context_id, event_get_object(params, "response")) {
    (Some(ctx), Some(resp_json)) =>
      match response_from_json(resp_json) {
        Some(resp) =>
          match find_page_state(state_ref.val, ctx) {
            Some(page_state) =>
              if stage == "started" {
                page_state.val.response_events.push(resp)
                dispatch_network_event(page_state, NetworkEvent::Response(resp))
              } else {
                page_state.val.response_completed_events.push(resp)
                dispatch_network_event(
                  page_state,
                  NetworkEvent::ResponseCompleted(resp),
                )
              }
            None => ()
          }
        None => ()
      }
    _ => ()
  }
}

///|
fn dispatch_network_event(
  page_state : Ref[PageState],
  event : NetworkEvent,
) -> Unit {
  for handler in page_state.val.network_listeners {
    handler(event)
  }
}

///|
fn handle_log_entry(state_ref : Ref[BrowserState], params : Json) -> Unit {
  let context_id = event_context_id(params)
  let level = event_get_string(params, "level").unwrap_or("info")
  let text = event_get_string(params, "text").unwrap_or("")
  let source = event_get_string(params, "source").unwrap_or("")
  match context_id {
    Some(ctx) =>
      match find_page_state(state_ref.val, ctx) {
        Some(page_state) =>
          page_state.val.console_messages.push({ level, text, source, })
        None => ()
      }
    None => ()
  }
}

///|
fn find_page_state(
  state : BrowserState,
  context_id : String,
) -> Ref[PageState]? {
  for ctx_state in state.contexts {
    for page_state in ctx_state.val.pages {
      if page_state.val.context_id == context_id {
        return Some(page_state)
      }
    }
  }
  match state.default_context {
    Some(ctx_ref) =>
      for page_state in ctx_ref.val.state.val.pages {
        if page_state.val.context_id == context_id {
          return Some(page_state)
        }
      }
    None => ()
  }
  None
}

///|
fn event_context_id(params : Json) -> String? {
  match event_get_string(params, "context") {
    Some(ctx) => Some(ctx)
    None => event_get_string(params, "browsingContext")
  }
}

///|
fn request_from_json(json : Json) -> Request? {
  match (event_get_string(json, "url"), event_get_string(json, "method")) {
    (Some(url), Some(method_)) => {
      let headers = match event_get_array(json, "headers") {
        Some(items) => headers_from_array(items)
        None => Headers::empty()
      }
      Some({ url_: url, method_, headers_: headers, })
    }
    _ => None
  }
}

///|
fn response_from_json(json : Json) -> Response? {
  let url = event_get_string(json, "url")
  let status = event_get_number(json, "status")
  let status_text = event_get_string(json, "status_text")
  match (url, status) {
    (Some(u), Some(code)) => {
      let headers = match event_get_array(json, "headers") {
        Some(items) => headers_from_array(items)
        None => Headers::empty()
      }
      Some({
        url_: u,
        status_: code.to_int(),
        status_text_: status_text.unwrap_or(""),
        headers_: headers,
        from_cache_: false,
        from_service_worker_: false,
      })
    }
    _ => None
  }
}

///|
fn headers_from_array(items : Array[Json]) -> Headers {
  let pairs : Array[(String, String)] = []
  for item in items {
    match (event_get_string(item, "name"), event_get_string(item, "value")) {
      (Some(name), Some(value)) => pairs.push((name, value))
      _ => ()
    }
  }
  Headers::from_pairs(pairs)
}

///|
fn event_get_string(json : Json, key : String) -> String? {
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
fn event_get_number(json : Json, key : String) -> Double? {
  match json {
    Object(map) =>
      match map.get(key) {
        Some(Number(value, ..)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn event_get_object(json : Json, key : String) -> Json? {
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
fn event_get_array(json : Json, key : String) -> Array[Json]? {
  match json {
    Object(map) =>
      match map.get(key) {
        Some(Array(items)) => Some(items)
        _ => None
      }
    _ => None
  }
}
