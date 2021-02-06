defmodule VisitedLinksTest do
  use ExUnit.Case
  use Plug.Test
  alias LinkStats.Endpoint

  @opts Endpoint.init([])

  test "warns about missing links field" do
    conn =
      conn(:post, "/visited_links", ~s({"lenks": []}))
      |> put_req_header("content-type", "application/json")
      |> Endpoint.call(@opts)

    assert conn.status == 422
    assert conn.resp_body =~ "missing"
  end

  test "warns about links field having wrong type" do
    conn =
      conn(:post, "/visited_links", ~s({"links": "google.com"}))
      |> put_req_header("content-type", "application/json")
      |> Endpoint.call(@opts)

    assert conn.status == 422
    assert conn.resp_body =~ "array"
  end

  test "adds links with scheme" do
    conn =
      conn(:post, "/visited_links", ~s({"links": ["https://google.com"]}))
      |> put_req_header("content-type", "application/json")
      |> Endpoint.call(@opts)

    assert conn.status == 200

    assert Redix.command!(:redix, ["ZRANGEBYSCORE", "domains", 1, 2_000_000_000]) |> hd() =~
             "google.com"

    Redix.command!(:redix, ["FLUSHDB"])
  end

  test "adds links without scheme" do
    conn =
      conn(:post, "/visited_links", ~s({"links": ["google.com"]}))
      |> put_req_header("content-type", "application/json")
      |> Endpoint.call(@opts)

    assert conn.status == 200

    assert Redix.command!(:redix, ["ZRANGEBYSCORE", "domains", 1, 2_000_000_000]) |> hd() =~
             "google.com"

    Redix.command!(:redix, ["FLUSHDB"])
  end

  test "adds links with query parameters" do
    conn =
      conn(:post, "/visited_links", ~s({"links": ["https://google.com/search?q=how+to+read"]}))
      |> put_req_header("content-type", "application/json")
      |> Endpoint.call(@opts)

    assert conn.status == 200

    assert Redix.command!(:redix, ["ZRANGEBYSCORE", "domains", 1, 2_000_000_000]) |> hd() =~
             "google.com"

    Redix.command!(:redix, ["FLUSHDB"])
  end
end
