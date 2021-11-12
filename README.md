# Gomoku

```
Base URL: http//gomoku.fly.dev/
```

## Game JSON

`player_1` will always be assigned to piece `"x"`
`player_1` will always be assigned to piece `"o"`
Empty pieces are considered `null`
```
{
  "player_1": String,
  "player_2": String,
  "next_move": String,
  "winner": null | String,
  "board": Array[size][size]: {
    [null,"x",null,null,"o"],
    [null,"x",null,null,"o"],
    ["x","x",null,null,"o"],
  }
```

## Start a new game

```
Method: POST

URL: :url/new_game/:game_id

JSON Post Data:
{
  "player_1": String,
  "player_2": String,
  "size"?: Int <- defaults to 20 if not present
}

Response: JSON
```

## Play an existing game

```
Method: PUT

URL: :url/play_game/:game_id

JSON Post Data: {
  "player": String,
  "x": Int,
  "y": Int
}
```

## End an existing game

```
Method: POST

URL: :url/end_game/:game_id
```

## View an existing game

```
Method: GET

URL: :url/view_game/:game_id
```

## View an existing game pretty

```
Method: GET

URL: :url/view_game/:game_id/pretty
```
