///| Tests for remote_value_to_json BiDi deserialization

///|
test "remote_value_to_json: string" {
  let rv : Json = { "type": "string", "value": "hello" }
  assert_eq(remote_value_to_json(rv), Json::string("hello"))
}

///|
test "remote_value_to_json: number" {
  let rv : Json = { "type": "number", "value": 42.0 }
  assert_eq(remote_value_to_json(rv), Json::number(42.0))
}

///|
test "remote_value_to_json: boolean true" {
  let rv : Json = { "type": "boolean", "value": true }
  assert_eq(remote_value_to_json(rv), Json::boolean(true))
}

///|
test "remote_value_to_json: boolean false" {
  let rv : Json = { "type": "boolean", "value": false }
  assert_eq(remote_value_to_json(rv), Json::boolean(false))
}

///|
test "remote_value_to_json: null" {
  let rv : Json = { "type": "null" }
  assert_eq(remote_value_to_json(rv), Json::null())
}

///|
test "remote_value_to_json: undefined" {
  let rv : Json = { "type": "undefined" }
  assert_eq(remote_value_to_json(rv), Json::null())
}

///|
test "remote_value_to_json: object with string values" {
  // BiDi format: { type: "object", value: [[key_rv, val_rv], ...] }
  let rv : Json = {
    "type": "object",
    "value": [
      [
        { "type": "string", "value": "name" },
        { "type": "string", "value": "Alice" },
      ],
      [
        { "type": "string", "value": "age" },
        { "type": "number", "value": 30.0 },
      ],
    ],
  }
  let result = remote_value_to_json(rv)
  match result {
    Object(m) => {
      assert_true(m.get("name") == Some(Json::string("Alice")))
      assert_true(m.get("age") == Some(Json::number(30.0)))
    }
    _ => fail("expected Object, got \{@debug.repr(result)}")
  }
}

///|
test "remote_value_to_json: empty object" {
  let rv : Json = { "type": "object", "value": Json::array([]) }
  let result = remote_value_to_json(rv)
  match result {
    Object(m) => assert_eq(m.length(), 0)
    _ => fail("expected empty Object")
  }
}

///|
test "remote_value_to_json: array of numbers" {
  let rv : Json = {
    "type": "array",
    "value": [
      { "type": "number", "value": 1.0 },
      { "type": "number", "value": 2.0 },
      { "type": "number", "value": 3.0 },
    ],
  }
  let result = remote_value_to_json(rv)
  match result {
    Array(items) => {
      assert_eq(items.length(), 3)
      assert_eq(items[0], Json::number(1.0))
      assert_eq(items[1], Json::number(2.0))
      assert_eq(items[2], Json::number(3.0))
    }
    _ => fail("expected Array")
  }
}

///|
test "remote_value_to_json: empty array" {
  let rv : Json = { "type": "array", "value": Json::array([]) }
  let result = remote_value_to_json(rv)
  match result {
    Array(items) => assert_eq(items.length(), 0)
    _ => fail("expected empty Array")
  }
}

///|
test "remote_value_to_json: nested object in array" {
  let rv : Json = {
    "type": "array",
    "value": [
      {
        "type": "object",
        "value": [
          [
            { "type": "string", "value": "x" },
            { "type": "number", "value": 1.0 },
          ],
        ],
      },
    ],
  }
  let result = remote_value_to_json(rv)
  match result {
    Array([Object(m)]) => assert_true(m.get("x") == Some(Json::number(1.0)))
    _ => fail("expected Array with Object")
  }
}

///|
test "remote_value_to_json: date returns ISO string" {
  let rv : Json = { "type": "date", "value": "2024-01-01T00:00:00Z" }
  assert_eq(remote_value_to_json(rv), Json::string("2024-01-01T00:00:00Z"))
}

///|
test "remote_value_to_json: map converts like object" {
  let rv : Json = {
    "type": "map",
    "value": [
      [
        { "type": "string", "value": "key" },
        { "type": "string", "value": "val" },
      ],
    ],
  }
  let result = remote_value_to_json(rv)
  match result {
    Object(m) => assert_true(m.get("key") == Some(Json::string("val")))
    _ => fail("expected Object from map")
  }
}

///|
test "remote_value_to_json: set converts to array" {
  let rv : Json = {
    "type": "set",
    "value": [
      { "type": "number", "value": 1.0 },
      { "type": "number", "value": 2.0 },
    ],
  }
  let result = remote_value_to_json(rv)
  match result {
    Array(items) => assert_eq(items.length(), 2)
    _ => fail("expected Array from set")
  }
}

///|
test "remote_value_to_json: node returns null" {
  let rv : Json = { "type": "node", "value": { "nodeType": 1.0 } }
  assert_eq(remote_value_to_json(rv), Json::null())
}

///|
test "remote_value_to_json: fetch response shape" {
  // Simulates: { status: 200, body: "ok" } as BiDi remote value
  let rv : Json = {
    "type": "object",
    "value": [
      [
        { "type": "string", "value": "status" },
        { "type": "number", "value": 200.0 },
      ],
      [
        { "type": "string", "value": "body" },
        { "type": "string", "value": "{\"status\":\"ok\"}" },
      ],
    ],
  }
  let result = remote_value_to_json(rv)
  match result {
    Object(m) => {
      assert_true(m.get("status") == Some(Json::number(200.0)))
      assert_true(m.get("body") == Some(Json::string("{\"status\":\"ok\"}")))
    }
    _ => fail("expected fetch response object")
  }
}
