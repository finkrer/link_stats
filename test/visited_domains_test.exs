defmodule VisitedDomainsTest do
  use ExUnit.Case
  use Plug.Test
  alias LinkStats.Endpoint

  @opts Endpoint.init([])

  test "warns about from/to missing" do
    conn = conn(:get, "/visited_domains") |> Endpoint.call(@opts)
    assert conn.status == 422
    assert conn.resp_body =~ "required"
  end

  test "warns about from/to having wrong type" do
    conn = conn(:get, "/visited_domains?from=test&to=test") |> Endpoint.call(@opts)
    assert conn.status == 422
    assert conn.resp_body =~ "integers"
  end

  test "returns domains if in range" do
    Redix.command!(:redix, [
      "ZADD",
      "domains",
      1_612_631_339,
      "[\"google.com@1612631339\",\"stackoverflow.com@1612631339\"]"
    ])

    conn = conn(:get, "/visited_domains?from=1&to=2000000000") |> Endpoint.call(@opts)
    assert conn.status == 200
    assert conn.resp_body =~ "google.com"
    assert conn.resp_body =~ "stackoverflow.com"

    Redix.command!(:redix, ["FLUSHDB"])
  end

  test "does not return domains if not in range" do
    Redix.command!(:redix, [
      "ZADD",
      "domains",
      1_612_631_339,
      "[\"google.com@1612631339\",\"stackoverflow.com@1612631339\"]"
    ])

    conn = conn(:get, "/visited_domains?from=1&to=1000000000") |> Endpoint.call(@opts)
    assert conn.status == 200
    refute conn.resp_body =~ "google.com"
    refute conn.resp_body =~ "stackoverflow.com"

    Redix.command!(:redix, ["FLUSHDB"])
  end

  test "only returns unique domains" do
    Redix.command!(:redix, [
      "ZADD",
      "domains",
      1_612_631_339,
      "[\"google.com@1612631339\"]"
    ])

    Redix.command!(:redix, [
      "ZADD",
      "domains",
      1_612_631_340,
      "[\"google.com@1612631340\"]"
    ])

    conn = conn(:get, "/visited_domains?from=1&to=2000000000") |> Endpoint.call(@opts)
    assert conn.status == 200
    assert conn.resp_body |> String.split("google.com") |> length() == 2

    Redix.command!(:redix, ["FLUSHDB"])
  end
end
