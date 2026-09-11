///|
async fn main {
  let args = @env.args()
  let browser = @pw.chromium().connect(args[args.length() - 2])
  defer browser.close()
  let page = browser.new_page()
  defer page.close()
  let html =
    #|<div id="content" data-kind="greeting" data-literal="null">Hello <b>world</b></div>
    #|<section id="scope">
    #|  <label for="name">Name</label><input id="name" value="Alice">
    #|  <label>Wrapped<input id="wrapped" value="Bob"></label>
    #|  <span id="caption">Account</span><input id="account" aria-labelledby="caption" value="Carol">
    #|  <input id="alias" aria-label="Alias" value="Dave">
    #|  <button id="save" onclick="this.dataset.clicked = 'yes'">Save</button>
    #|  <button id="skip">Save draft</button>
    #|</section>
    #|<input id="outside" aria-label="Alias" value="Outside">
  page.set_content(html)
  match args[args.length() - 1] {
    "content" => {
      let content = page.locator("#content")
      assert_eq(content.text_content(), Some("Hello world"))
      assert_eq(content.inner_text(), "Hello world")
      assert_eq(content.inner_html(), "Hello <b>world</b>")
      assert_eq(content.get_attribute("data-kind"), Some("greeting"))
      assert_eq(content.get_attribute("data-literal"), Some("null"))
      assert_eq(content.get_attribute("missing"), None)
      assert_eq(page.locator("#missing").text_content(), None)
    }
    "labels" => {
      assert_eq(page.get_by_label("Name", exact=true).input_value(), "Alice")
      assert_eq(page.get_by_label("Wrapped").input_value(), "Bob")
      assert_eq(page.get_by_label("Account").input_value(), "Carol")
      let scoped = page.locator("#scope").get_by_label("Alias", exact=true)
      assert_eq(scoped.input_value(), "Dave")
    }
    "text" => {
      page.get_by_text("Save", exact=true).click()
      assert_eq(
        page.locator("#save").get_attribute("data-clicked"),
        Some("yes"),
      )
      let filtered = page
        .locator("button")
        .filter(has_text="Save", has_not_text="draft")
      assert_eq(filtered.get_attribute("id"), Some("save"))
      assert_eq(
        page.locator("button").filter(has_not_text="draft").inner_text(),
        "Save",
      )
    }
    _ => fail("unknown DOM regression scenario")
  }
}
