///|
/// Core types and internal state

///|
pub enum BrowserKind {
  Chromium
  Firefox
  WebKit
} derive(Eq, @debug.Debug)

///|
pub impl Show for BrowserKind with fn output(self, logger) {
  match self {
    Chromium => logger.write_string("Chromium")
    Firefox => logger.write_string("Firefox")
    WebKit => logger.write_string("WebKit")
  }
}

///|
pub struct BrowserType {
  kind : BrowserKind
}

///|
pub impl Show for BrowserType with fn output(self, logger) {
  logger.write_string("{kind: ")
  logger.write_object(self.kind)
  logger.write_char('}')
}

///|
pub struct Browser {
  priv state : Ref[BrowserState]
}

///|
pub struct BrowserContext {
  priv state : Ref[BrowserContextState]
}

///|
pub struct Page {
  priv state : Ref[PageState]
}

///|
pub struct Locator {
  priv state : Ref[LocatorState]
}

///|
pub struct Response {
  url_ : String
  status_ : Int
  status_text_ : String
  headers_ : Headers
  from_cache_ : Bool
  from_service_worker_ : Bool
}

///|
pub impl Show for Response with fn output(self, logger) {
  logger.write_string("{url_: ")
  logger.write_object(self.url_)
  logger.write_string(", status_: ")
  logger.write_object(self.status_)
  logger.write_string(", status_text_: ")
  logger.write_object(self.status_text_)
  logger.write_string(", headers_: ")
  logger.write_object(self.headers_)
  logger.write_string(", from_cache_: ")
  logger.write_object(self.from_cache_)
  logger.write_string(", from_service_worker_: ")
  logger.write_object(self.from_service_worker_)
  logger.write_char('}')
}

///|
pub struct Request {
  url_ : String
  method_ : String
  headers_ : Headers
}

///|
pub impl Show for Request with fn output(self, logger) {
  logger.write_string("{url_: ")
  logger.write_object(self.url_)
  logger.write_string(", method_: ")
  logger.write_object(self.method_)
  logger.write_string(", headers_: ")
  logger.write_object(self.headers_)
  logger.write_char('}')
}

///|
pub struct Frame {
  url_ : String
  name_ : String
}

///|
pub impl Show for Frame with fn output(self, logger) {
  logger.write_string("{url_: ")
  logger.write_object(self.url_)
  logger.write_string(", name_: ")
  logger.write_object(self.name_)
  logger.write_char('}')
}

///|
pub enum NetworkEvent {
  Request(Request)
  Response(Response)
  ResponseCompleted(Response)
}

///|
pub impl Show for NetworkEvent with fn output(self, logger) {
  match self {
    Request(value) => {
      logger.write_string("Request(")
      logger.write_object(value)
      logger.write_char(')')
    }
    Response(value) => {
      logger.write_string("Response(")
      logger.write_object(value)
      logger.write_char(')')
    }
    ResponseCompleted(value) => {
      logger.write_string("ResponseCompleted(")
      logger.write_object(value)
      logger.write_char(')')
    }
  }
}

///|
pub suberror PlaywrightError {
  StrictModeViolation(selector~ : String, count~ : Int)
} derive(Eq, @debug.Debug)

///|
pub impl Show for PlaywrightError with fn output(self, logger) {
  match self {
    StrictModeViolation(selector~, count~) => {
      logger.write_string("StrictModeViolation(selector=")
      logger.write_object(selector)
      logger.write_string(", count=")
      logger.write_object(count)
      logger.write_char(')')
    }
  }
}

///|
/// Structured data types

///|
pub struct Headers {
  entries : Array[(String, String)]
} derive(Eq, @debug.Debug)

///|
pub impl Show for Headers with fn output(self, logger) {
  logger.write_string("{entries: ")
  logger.write_string(@debug.repr(self.entries))
  logger.write_char('}')
}

///|
pub struct Cookie {
  name : String
  value : String
  url : String?
  domain : String?
  path : String?
  expires : Double?
  http_only : Bool?
  secure : Bool?
  same_site : String?
} derive(Eq, @debug.Debug)

///|
pub impl Show for Cookie with fn output(self, logger) {
  logger.write_string("{name: ")
  logger.write_object(self.name)
  logger.write_string(", value: ")
  logger.write_string(@debug.repr(self.value))
  logger.write_string(", url: ")
  logger.write_string(@debug.repr(self.url))
  logger.write_string(", domain: ")
  logger.write_string(@debug.repr(self.domain))
  logger.write_string(", path: ")
  logger.write_string(@debug.repr(self.path))
  logger.write_string(", expires: ")
  logger.write_string(@debug.repr(self.expires))
  logger.write_string(", http_only: ")
  logger.write_string(@debug.repr(self.http_only))
  logger.write_string(", secure: ")
  logger.write_string(@debug.repr(self.secure))
  logger.write_string(", same_site: ")
  logger.write_string(@debug.repr(self.same_site))
  logger.write_char('}')
}

///|
pub struct SelectOption {
  value : String?
  label : String?
  index : Int?
} derive(Eq, @debug.Debug)

///|
pub impl Show for SelectOption with fn output(self, logger) {
  logger.write_string("{value: ")
  logger.write_string(@debug.repr(self.value))
  logger.write_string(", label: ")
  logger.write_string(@debug.repr(self.label))
  logger.write_string(", index: ")
  logger.write_string(@debug.repr(self.index))
  logger.write_char('}')
}

///|
pub enum Length {
  Points(Double)
  Css(String)
} derive(Eq, @debug.Debug)

///|
pub impl Show for Length with fn output(self, logger) {
  match self {
    Points(value) => {
      logger.write_string("Points(")
      logger.write_object(value)
      logger.write_char(')')
    }
    Css(value) => {
      logger.write_string("Css(")
      logger.write_object(value)
      logger.write_char(')')
    }
  }
}

///|
pub struct Margin {
  top : Length?
  right : Length?
  bottom : Length?
  left : Length?
} derive(Eq, @debug.Debug)

///|
pub impl Show for Margin with fn output(self, logger) {
  logger.write_string("{top: ")
  logger.write_string(@debug.repr(self.top))
  logger.write_string(", right: ")
  logger.write_string(@debug.repr(self.right))
  logger.write_string(", bottom: ")
  logger.write_string(@debug.repr(self.bottom))
  logger.write_string(", left: ")
  logger.write_string(@debug.repr(self.left))
  logger.write_char('}')
}

///|
pub struct Clip {
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, @debug.Debug)

///|
pub impl Show for Clip with fn output(self, logger) {
  logger.write_string("{x: ")
  logger.write_object(self.x)
  logger.write_string(", y: ")
  logger.write_object(self.y)
  logger.write_string(", width: ")
  logger.write_object(self.width)
  logger.write_string(", height: ")
  logger.write_object(self.height)
  logger.write_char('}')
}

///|
pub struct BoundingBox {
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, @debug.Debug)

///|
pub impl Show for BoundingBox with fn output(self, logger) {
  logger.write_string("{x: ")
  logger.write_object(self.x)
  logger.write_string(", y: ")
  logger.write_object(self.y)
  logger.write_string(", width: ")
  logger.write_object(self.width)
  logger.write_string(", height: ")
  logger.write_object(self.height)
  logger.write_char('}')
}

///|
pub fn Headers::empty() -> Headers {
  { entries: [], }
}

///|
pub fn Headers::from_pairs(entries : Array[(String, String)]) -> Headers {
  { entries, }
}

///|
pub fn Headers::from_json(json : Json) -> Headers {
  match json {
    Object(map) => {
      let entries : Array[(String, String)] = []
      for entry in map.to_array() {
        let key = entry.0
        let value = match entry.1 {
          String(s) => Some(s)
          Number(n, ..) => Some(n.to_string())
          True => Some("true")
          False => Some("false")
          _ => None
        }
        match value {
          Some(v) => entries.push((key, v))
          None => ()
        }
      }
      { entries, }
    }
    _ => Headers::empty()
  }
}

///|
pub fn Headers::to_json(self : Headers) -> Json {
  let map : Map[String, Json] = Map([])
  for entry in self.entries {
    map.set(entry.0, Json::string(entry.1))
  }
  Json::object(map)
}

///|
pub fn Headers::get(self : Headers, key : String) -> String? {
  for entry in self.entries {
    if entry.0 == key {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn Cookie::from_json(json : Json) -> Cookie? {
  match (json_get_string(json, "name"), json_get_string(json, "value")) {
    (Some(name), Some(value)) =>
      Some({
        name,
        value,
        url: json_get_string(json, "url"),
        domain: json_get_string(json, "domain"),
        path: json_get_string(json, "path"),
        expires: json_get_number(json, "expires"),
        http_only: json_get_bool(json, "http_only"),
        secure: json_get_bool(json, "secure"),
        same_site: json_get_string(json, "same_site"),
      })
    _ => None
  }
}

///|
pub fn Cookie::new(
  name : String,
  value : String,
  url? : String,
  domain? : String,
  path? : String,
  expires? : Double,
  http_only? : Bool,
  secure? : Bool,
  same_site? : String,
) -> Cookie {
  { name, value, url, domain, path, expires, http_only, secure, same_site, }
}

///|
pub fn Cookie::to_json(self : Cookie) -> Json {
  let map : Map[String, Json] = Map([])
  map.set("name", Json::string(self.name))
  map.set("value", Json::string(self.value))
  match self.url {
    Some(value) => map.set("url", Json::string(value))
    None => ()
  }
  match self.domain {
    Some(value) => map.set("domain", Json::string(value))
    None => ()
  }
  match self.path {
    Some(value) => map.set("path", Json::string(value))
    None => ()
  }
  match self.expires {
    Some(value) => map.set("expires", Json::number(value))
    None => ()
  }
  match self.http_only {
    Some(value) => map.set("http_only", Json::boolean(value))
    None => ()
  }
  match self.secure {
    Some(value) => map.set("secure", Json::boolean(value))
    None => ()
  }
  match self.same_site {
    Some(value) => map.set("same_site", Json::string(value))
    None => ()
  }
  Json::object(map)
}

///|
pub fn SelectOption::from_value(value : String) -> SelectOption {
  { value: Some(value), label: None, index: None, }
}

///|
pub fn SelectOption::new(
  value? : String,
  label? : String,
  index? : Int,
) -> SelectOption {
  { value, label, index, }
}

///|
pub fn SelectOption::to_json(self : SelectOption) -> Json {
  let map : Map[String, Json] = Map([])
  match self.value {
    Some(value) => map.set("value", Json::string(value))
    None => ()
  }
  match self.label {
    Some(value) => map.set("label", Json::string(value))
    None => ()
  }
  match self.index {
    Some(value) => map.set("index", Json::number(value.to_double()))
    None => ()
  }
  Json::object(map)
}

///|
pub fn Length::to_json(self : Length) -> Json {
  match self {
    Points(value) => Json::number(value)
    Css(value) => Json::string(value)
  }
}

///|
pub fn Length::points(value : Double) -> Length {
  Points(value)
}

///|
pub fn Length::css(value : String) -> Length {
  Css(value)
}

///|
pub fn Margin::to_json(self : Margin) -> Json {
  let map : Map[String, Json] = Map([])
  match self.top {
    Some(value) => map.set("top", value.to_json())
    None => ()
  }
  match self.right {
    Some(value) => map.set("right", value.to_json())
    None => ()
  }
  match self.bottom {
    Some(value) => map.set("bottom", value.to_json())
    None => ()
  }
  match self.left {
    Some(value) => map.set("left", value.to_json())
    None => ()
  }
  Json::object(map)
}

///|
pub fn Margin::new(
  top? : Length,
  right? : Length,
  bottom? : Length,
  left? : Length,
) -> Margin {
  { top, right, bottom, left, }
}

///|
pub fn Clip::to_json(self : Clip) -> Json {
  Json::object({
    "x": Json::number(self.x),
    "y": Json::number(self.y),
    "width": Json::number(self.width),
    "height": Json::number(self.height),
  })
}

///|
pub fn Clip::new(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> Clip {
  { x, y, width, height, }
}

///|
pub fn BoundingBox::from_json(json : Json) -> BoundingBox? {
  match
    (
      json_get_number(json, "x"),
      json_get_number(json, "y"),
      json_get_number(json, "width"),
      json_get_number(json, "height"),
    ) {
    (Some(x), Some(y), Some(width), Some(height)) =>
      Some({ x, y, width, height, })
    _ => None
  }
}

///|
pub fn BoundingBox::new(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> BoundingBox {
  { x, y, width, height, }
}

///|
pub fn BoundingBox::to_json(self : BoundingBox) -> Json {
  Json::object({
    "x": Json::number(self.x),
    "y": Json::number(self.y),
    "width": Json::number(self.width),
    "height": Json::number(self.height),
  })
}

///|
fn json_get_string(json : Json, key : String) -> String? {
  match json {
    Object(map) =>
      match map.get(key) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn json_get_number(json : Json, key : String) -> Double? {
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
fn json_get_bool(json : Json, key : String) -> Bool? {
  match json {
    Object(map) =>
      match map.get(key) {
        Some(True) => Some(true)
        Some(False) => Some(false)
        _ => None
      }
    _ => None
  }
}

///|
priv struct BrowserState {
  kind : BrowserKind
  client : @bidi.BidiClient
  mut connected : Bool
  contexts : Array[Ref[BrowserContextState]]
  mut default_context : Ref[BrowserContext]?
}

///|
priv struct BrowserContextState {
  browser : Browser
  user_context : String
  pages : Array[Ref[PageState]]
}

///|
priv struct NavigationEvent {
  event_name : String
  url : String
}

///|
/// Console message collected from log.entryAdded events
pub(all) struct ConsoleMessage {
  level : String
  text : String
  source : String
}

///|
priv struct PageState {
  browser : Browser
  context : BrowserContext
  context_id : String
  mut url : String
  navigation_events : Array[NavigationEvent]
  network_listeners : Array[(NetworkEvent) -> Unit]
  request_events : Array[Request]
  response_events : Array[Response]
  response_completed_events : Array[Response]
  console_messages : Array[ConsoleMessage]
}

///|
priv struct LocatorState {
  page : Page
  selector : String
  index : Int?
  has_text : String?
  has_text_exact : Bool
  has_not_text : String?
  label_text : String?
  label_text_exact : Bool
  label_scope_selector : String?
}
