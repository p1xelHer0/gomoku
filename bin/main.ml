open Gomoku

type new_game_body = {
  size : int; [@default 15]
  player_1 : string;
  player_2 : string;
}
[@@deriving of_yojson]

type player_move_body = {
  player : string;
  x : int;
  y : int;
}
[@@deriving of_yojson]

let parse_new_game body =
  body |> Yojson.Safe.from_string |> new_game_body_of_yojson

let parse_player_move body =
  body |> Yojson.Safe.from_string |> player_move_body_of_yojson

module Games = Map.Make (String)

module State = struct
  type t = Game.t Games.t

  let games = ref Games.empty
  let add_game id game games = Games.add id game games
  let remove_game id games = Games.remove id games
  let get_game id games = Games.find_opt id games
end

let new_game request =
  let game_id = Dream.param "game_id" request in
  match State.get_game game_id !State.games with
  | None -> (
      try
        let%lwt body = Dream.body request in

        let { player_1; player_2; size } = parse_new_game body in

        let player_1 = Player.make player_1 in
        let player_2 = Player.make player_2 in

        match Game.make ~size ~player_1 ~player_2 ~game_id with
        | Error (`Board_Size_Too_Small (size, min_size, max_size)) ->
            Dream.json
              ("The Board size of the game needs to be between"
              ^ string_of_int min_size
              ^ " and "
              ^ string_of_int max_size
              ^ ", "
              ^ string_of_int size
              ^ " is too small")
        | Error (`Board_Size_Too_Big (size, min_size, max_size)) ->
            Dream.json
              ("The Board size of the game needs to be between"
              ^ string_of_int min_size
              ^ " and "
              ^ string_of_int max_size
              ^ ", "
              ^ string_of_int size
              ^ " is too big")
        | Ok new_game ->
            State.games := State.add_game game_id new_game !State.games;
            new_game |> Game.to_json |> Dream.json
      with
      | _ -> Dream.json "Invalid POST data for new_game")
  | Some _game -> Dream.json ("Game with ID #" ^ game_id ^ " already exists")

let end_game request =
  let game_id = Dream.param "game_id" request in
  match State.get_game game_id !State.games with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " doest not exist")
  | Some _game ->
      State.games := State.remove_game game_id !State.games;
      Dream.empty `OK

let play_game request =
  let open Game in
  let game_id = Dream.param "game_id" request in
  match State.get_game game_id !State.games with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " doest not exist")
  | Some game -> (
      match game.winner with
      | None -> (
          try
            let%lwt body = Dream.body request in

            let { player; x; y } = parse_player_move body in

            let player = Player.make player in
            let coordinate = Coordinate.make ~x ~y in

            match Game.play_game ~player ~coordinate ~game with
            | Error (`Board_Not_Game_Size (_new_size, _old_size)) ->
                Dream.json "Something went very wrong! xD"
            | Error (`Player_Not_Part_Of_Game (player, game_id)) ->
                Dream.json
                  ("Player "
                  ^ Player.to_string player
                  ^ " is not a part of Game with ID #"
                  ^ game_id)
            | Error (`Player_Not_Next player) ->
                Dream.json
                  ("It's not player " ^ Player.to_string player ^ "s turn")
            | Error (`Piece_Already_Placed coordinate) ->
                Dream.json
                  ("Piece on coordinates "
                  ^ Coordinate.to_string coordinate
                  ^ " has already been placed")
            | Error (`Piece_Out_Of_Bounds coordinate) ->
                Dream.json
                  ("Piece on coordinates "
                  ^ Coordinate.to_string coordinate
                  ^ " would be placed out of bounds")
            | Ok game ->
                State.games := State.add_game game_id game !State.games;
                game |> Game.to_json |> Dream.json
          with
          | _ -> Dream.json "Invalid PUT data for play_game")
      | Some winner ->
          Dream.json
            ("Game with ID #"
            ^ game.id
            ^ " has already been won by player "
            ^ winner))

let view_game request =
  let game_id = Dream.param "game_id" request in
  match State.get_game game_id !State.games with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " does not exist")
  | Some game -> game |> Game.to_json |> Dream.json

let view_game_pretty request =
  let game_id = Dream.param "game_id" request in
  match State.get_game game_id !State.games with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " does not exist")
  | Some game -> Game.to_string game |> Dream.json

let view_all_games _request =
  let game_id = "123" in
  match State.get_game game_id !State.games with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " does not exist")
  | Some game -> Game.to_string game |> Dream.json

let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router
       [
         Dream.post "/new_game/:game_id" (fun request -> new_game request);
         Dream.put "/play_game/:game_id" (fun request -> play_game request);
         Dream.post "/end_game/:game_id" (fun request -> end_game request);
         Dream.get "/view_game/:game_id" (fun request -> view_game request);
         Dream.get "/view_game/:game_id/pretty" (fun request ->
             view_game_pretty request);
         Dream.get "/view_all_games" (fun request -> view_all_games request);
       ]
  @@ Dream.not_found
