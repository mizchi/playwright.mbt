///|
/// Response body helpers

///|
pub enum ResponseBody {
  Text(String)
  JsonValue(Json)
  Bytes(Bytes)
}

///|
pub impl Show for ResponseBody with fn output(self, logger) {
  match self {
    Text(value) => {
      logger.write_string("Text(")
      logger.write_string(@debug.repr(value))
      logger.write_char(')')
    }
    JsonValue(value) => {
      logger.write_string("JsonValue(")
      logger.write_string(@debug.repr(value))
      logger.write_char(')')
    }
    Bytes(value) => {
      logger.write_string("Bytes(")
      logger.write_string(@debug.repr(value))
      logger.write_char(')')
    }
  }
}

///|
pub fn ResponseBody::text(value : String) -> ResponseBody {
  Text(value)
}

///|
pub fn ResponseBody::json(value : Json) -> ResponseBody {
  JsonValue(value)
}

///|
pub fn ResponseBody::bytes(value : Bytes) -> ResponseBody {
  Bytes(value)
}

///|
pub fn ResponseBody::as_text(self : ResponseBody) -> String? {
  match self {
    Text(value) => Some(value)
    _ => None
  }
}

///|
pub fn ResponseBody::as_json(self : ResponseBody) -> Json? {
  match self {
    JsonValue(value) => Some(value)
    _ => None
  }
}

///|
pub fn ResponseBody::as_bytes(self : ResponseBody) -> Bytes? {
  match self {
    Bytes(value) => Some(value)
    _ => None
  }
}
