defmodule BankingSandboxWeb.PageLiveTest do
  use BankingSandboxWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Phoenix Framework"
    assert render(page_live) =~ "Accounts"
  end

  test "connected mount", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Live Bank Server"
  end
end
