# LinkStats

A simple JSON API storing link stats in Redis.

Post links:

```json
POST /visited_links

{
  "links": [
      "https://ya.ru",
      "https://ya.ru?q=123",
      "https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"
  ]
}
```

Then get stats:

```json
GET /visited_domains?from=1545221231&to=1545217638

{
  "domains": [
    "ya.ru",
    "stackoverflow.com"
  ],
  "status": "ok"
}
```

## To run

Make sure there is a Redis server available at port 6379.

```sh
mix deps.get
mix run --no-halt
```

## To test

```sh
mix test
```
