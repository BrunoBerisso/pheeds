defmodule PheedsWeb.ErrorJSONTest do
  use PheedsWeb.ConnCase, async: true

  test "renders 404" do
    assert PheedsWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert PheedsWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
