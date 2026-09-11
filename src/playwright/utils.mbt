///|
/// JSON and JS helpers

///|
fn json_get_object(json : Json, key : String) -> Json? {
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
fn json_get_array(json : Json, key : String) -> Array[Json]? {
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
fn js_string_literal(value : String) -> String {
  let sb = StringBuilder()
  sb.write_char('"')
  for ch in value {
    match ch {
      '"' => sb.write_view("\\\"")
      '\\' => sb.write_view("\\\\")
      '\n' => sb.write_view("\\n")
      '\r' => sb.write_view("\\r")
      '\t' => sb.write_view("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
/// Convert a WebDriver BiDi RemoteValue to MoonBit Json.
/// Handles primitives (string, number, boolean, null, undefined)
/// and recursively converts objects and arrays.
/// See: https://w3c.github.io/webdriver-bidi/#type-script-RemoteValue
fn remote_value_to_json(value : Json) -> Json {
  match value {
    Object(map) =>
      match map.get("type") {
        Some(String("string")) =>
          match map.get("value") {
            Some(String(s)) => Json::string(s)
            _ => Json::string("")
          }
        Some(String("number")) =>
          match map.get("value") {
            Some(Number(n, ..)) => Json::number(n)
            // BiDi encodes special numbers as strings
            Some(String("NaN")) => Json::number(0.0 / 0.0)
            Some(String("Infinity")) => Json::number(1.0 / 0.0)
            Some(String("-Infinity")) => Json::number(-1.0 / 0.0)
            Some(String("-0")) => Json::number(-0.0)
            _ => Json::number(0.0)
          }
        Some(String("boolean")) =>
          match map.get("value") {
            Some(True) => Json::boolean(true)
            Some(False) => Json::boolean(false)
            _ => Json::boolean(false)
          }
        Some(String("null")) | Some(String("undefined")) => Json::null()
        // Object: { type: "object", value: [[key_rv, val_rv], ...] }
        Some(String("object")) =>
          match map.get("value") {
            Some(Array(entries)) => {
              let obj : Map[String, Json] = Map([])
              for entry in entries {
                match entry {
                  Array([key_rv, val_rv]) =>
                    match remote_value_to_string(key_rv) {
                      Some(key) => obj[key] = remote_value_to_json(val_rv)
                      None => ()
                    }
                  _ => ()
                }
              }
              Json::object(obj)
            }
            _ => Json::null()
          }
        // Array: { type: "array", value: [rv, rv, ...] }
        Some(String("array")) =>
          match map.get("value") {
            Some(Array(items)) =>
              Json::array(items.map(fn(item) { remote_value_to_json(item) }))
            _ => Json::array([])
          }
        // Map: { type: "map", value: [[key_rv, val_rv], ...] }
        Some(String("map")) =>
          match map.get("value") {
            Some(Array(entries)) => {
              let obj : Map[String, Json] = Map([])
              for entry in entries {
                match entry {
                  Array([key_rv, val_rv]) =>
                    match remote_value_to_string(key_rv) {
                      Some(key) => obj[key] = remote_value_to_json(val_rv)
                      None => ()
                    }
                  _ => ()
                }
              }
              Json::object(obj)
            }
            _ => Json::null()
          }
        // Set: { type: "set", value: [rv, rv, ...] }
        Some(String("set")) =>
          match map.get("value") {
            Some(Array(items)) =>
              Json::array(items.map(fn(item) { remote_value_to_json(item) }))
            _ => Json::array([])
          }
        // Date: { type: "date", value: "ISO string" }
        Some(String("date")) =>
          match map.get("value") {
            Some(String(s)) => Json::string(s)
            _ => Json::null()
          }
        // RegExp: { type: "regexp", value: { pattern, flags } }
        Some(String("regexp")) =>
          match map.get("value") {
            Some(Object(rv)) =>
              match rv.get("pattern") {
                Some(String(p)) => Json::string(p)
                _ => Json::null()
              }
            _ => Json::null()
          }
        // Node/Window/etc. — return null
        Some(String("node")) | Some(String("window")) => Json::null()
        _ => value
      }
    _ => value
  }
}

///|
fn remote_value_to_string(value : Json) -> String? {
  match value {
    // Bare string (not wrapped in {type:"string",value:...})
    String(s) => Some(s)
    Number(n, ..) => Some(n.to_string())
    True => Some("true")
    False => Some("false")
    Object(map) =>
      match map.get("type") {
        Some(String("string")) =>
          match map.get("value") {
            Some(String(s)) => Some(s)
            _ => None
          }
        Some(String("number")) =>
          match map.get("value") {
            Some(Number(n, ..)) => Some(n.to_string())
            _ => None
          }
        Some(String("boolean")) =>
          match map.get("value") {
            Some(True) => Some("true")
            Some(False) => Some("false")
            _ => None
          }
        Some(String("null")) => Some("null")
        Some(String("undefined")) => Some("undefined")
        _ => None
      }
    _ => None
  }
}

///|
fn[T] consume(value : T) -> Unit {
  let _ = value
}

///|
/// Detect if a string looks like a JavaScript function expression.
/// Returns true for: "() => ...", "(a) => ...", "function(...", "async (...", "async function"
fn is_function_expression(s : String) -> Bool {
  let trimmed = s.trim().to_owned()
  if trimmed.has_prefix("function") ||
    trimmed.has_prefix("async function") ||
    trimmed.has_prefix("async (") ||
    trimmed.has_prefix("async()") {
    return true
  }
  // Inspect the complete parameter group so an IIFE is evaluated as an
  // expression, rather than passing its result to script.callFunction.
  if trimmed.has_prefix("(") {
    let mut depth = 0
    let mut quote : Char? = None
    let mut escaped = false
    for index, ch in trimmed {
      match quote {
        Some(delimiter) =>
          if escaped {
            escaped = false
          } else if ch == '\\' {
            escaped = true
          } else if ch == delimiter {
            quote = None
          }
        None =>
          match ch {
            '\'' | '"' | '`' => quote = Some(ch)
            '(' => depth = depth + 1
            ')' => {
              depth = depth - 1
              if depth == 0 {
                let rest = trimmed[index + 1:].trim()
                return if rest.is_empty() {
                  is_function_expression(trimmed[1:index].to_owned())
                } else {
                  rest.has_prefix("=>")
                }
              }
            }
            _ => ()
          }
      }
    }
    return false
  }
  // Single-param arrow: "x => ..."
  match trimmed.find("=>") {
    Some(index) => {
      let parameter = trimmed[:index].trim().to_owned()
      let parameter = if parameter.has_prefix("async ") {
        parameter[6:].trim().to_owned()
      } else {
        parameter
      }
      !parameter.is_empty() &&
      parameter
      .iter()
      .all(ch => {
        (ch >= 'a' && ch <= 'z') ||
        (ch >= 'A' && ch <= 'Z') ||
        (ch >= '0' && ch <= '9') ||
        ch == '_' ||
        ch == '$'
      })
    }
    None => false
  }
}

///|
let noop_client : @bidi.BidiClient = @bidi.BidiClient::new(
  @bidi.Transport::unsupported("noop"),
)

///|
async fn async_noop() -> Unit {
  let _ = noop_client.connect()
}

///|
async fn sleep_ms(ms : Int) -> Unit {
  if ms <= 0 {
    return
  }
  let queue : @async.Queue[Unit] = @async.Queue(kind=@aqueue.Kind::Unbounded)
  let _ = @async.with_timeout_opt(ms, async fn() -> Unit { queue.get() })
}

///|
fn json_to_remote_value(value : Json) -> Json {
  match value {
    String(s) =>
      Json::object({ "type": Json::string("string"), "value": Json::string(s) })
    Number(n, ..) =>
      Json::object({ "type": Json::string("number"), "value": Json::number(n) })
    True =>
      Json::object({
        "type": Json::string("boolean"),
        "value": Json::boolean(true),
      })
    False =>
      Json::object({
        "type": Json::string("boolean"),
        "value": Json::boolean(false),
      })
    Null => Json::object({ "type": Json::string("null") })
    _ => value
  }
}
