defmodule AwesomeListWeb.PageControllerTest do
  use AwesomeListWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    resp = html_response(conn, 200)
    assert resp =~ "Libraries and tools for working with actors and such."
    assert resp =~ "Algorithms and Data structures"
    assert resp =~ "Applications"
    assert resp |> String.split("</li>") |> length == 15
  end

  test "GET /?min_stars=incorrect", %{conn: conn} do
    conn = get(conn, "/?min_stars=incorrect")
    resp = html_response(conn, 200)
    assert resp =~ "Cannot parse incorrect"
  end

  test "GET /?min_stars=500", %{conn: conn} do
    conn = get(conn, "/?min_stars=500")
    resp = html_response(conn, 200)
    assert resp |> String.split("</li>") |> length == 4

    assert resp =~ "Actors"
    refute resp =~ "Algorithms and Data structures"
    refute resp =~ "Applications"
  end

  test "GET /?min_stars=50000", %{conn: conn} do
    conn = get(conn, "/?min_stars=50000")
    resp = html_response(conn, 200)

    refute resp =~ "Actors"
    refute resp =~ "Algorithms and Data structures"
    refute resp =~ "Applications"
  end
end
