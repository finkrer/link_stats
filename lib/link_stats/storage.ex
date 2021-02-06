defmodule LinkStats.Storage do
  @spec get_domains(non_neg_integer, non_neg_integer) :: list(String.t())
  def get_domains(from, to) do
    Redix.command!(:redix, ["ZRANGEBYSCORE", "domains", from, to])
    |> Enum.map(fn entry ->
      Jason.decode!(entry)
      |> Enum.map(fn domain ->
        [domain, _timestamp] = String.split(domain, "@")
        domain
      end)
    end)
    |> List.flatten()
    |> Enum.uniq()
  end

  @spec add_domains(list(String.t()), non_neg_integer()) :: {:ok} | {:error, String.t()}
  def add_domains(list, timestamp) do
    if not is_list(list) do
      {:error, ~s("links" was not an array)}
    else
      domains =
        for link <- list, into: [] do
          link = if not String.starts_with?(link, "http"), do: "https://" <> link, else: link
          uri = URI.parse(link)

          case uri.host do
            nil -> nil
            host -> "#{host}@#{timestamp}"
          end
        end

      if nil in domains do
        {:error, "one of the links contained an invalid domain"}
      else
        value = Jason.encode!(domains)
        Redix.command!(:redix, ["ZADD", "domains", timestamp, value])
        {:ok}
      end
    end
  end
end
