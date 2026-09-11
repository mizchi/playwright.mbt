# Changelog

## 0.3.9

- Fix DOM text, HTML, and attribute getters and text/label locators to use the browser's JavaScript API names.
- Return `None` for missing DOM attributes and elements, while preserving literal string values such as `"null"`.
- Fix generated label lookup JavaScript and send capabilities when creating a BiDi session.
- Add Chromium integration coverage for DOM getters, label lookup, text filtering, and clicks through the MoonBit API.

## 0.3.8

- Support the current MoonBit compiler and standard library, and update `moonbitlang/async` to 0.21.3.
- Migrate the module manifest to `moon.mod`.
- Preserve `Eq + Show` compatibility for equality matchers and the `method=` label on page fetch helpers.
- Distinguish immediately invoked JavaScript expressions from functions passed to `Page::evaluate`.
- Run the integration test by default instead of selecting an empty shard.
