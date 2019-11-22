# VisitedServer

Web server provides JSON API to store visited links and query visited domains fith time filtering.

## API
1. Store domains of provided links
   Request:
   ```
   POST /visited_links
   {
     "links": [
       "https://ya.ru",
       "https://ya.ru?q=123",
       "funbox.ru",
       "https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"
       ]
   }
   ```

   Response:
   ```
   {
     "status": "ok"
   }
   ```

2. Get visited domains filtered by time range

   Request:
   `GET /visited_domains?from=1545217638&to=1545221231`

   Response:
   ```
   {
     "domains": [
       "ya.ru",
       "funbox.ru",
       "stackoverflow.com"
     ],
     "status": "ok"
   }
   ```

## Running

First, get project dependencies:
`mix deps.get`

Configuration files can be found in `./config/` folder.
Server port and Redis DB parameters are available.

Use the following command to run server from root folder:
`mix run --no-halt`

Testsuite can be run with:
`mix test`

## Accessing API

Following commands can be used to access API from command line:
```
curl -H 'Content-Type: application/json' -d '{"links": ["https://ya.ru","https://ya.ru?q=123","funbox.ru","https://stackoverflow.com/questions/11828270/how-to-exit-the-vim-editor"]}' 'http://localhost:8080/visited_links'

curl 'http://localhost:8080/visited_domains?from=1545221231&to=1545217638'
```
