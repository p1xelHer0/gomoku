type player_move_body = { player : string; x : int; y : int }
[@@deriving yojson]

type new_game_body = {
  size : int; [@default 20]
  player_1 : string;
  player_2 : string;
}
[@@deriving yojson]

module Coordinate = struct
  type t = { x : int; y : int }

  let make ~x ~y = { x; y }

  let pretty coordinate =
    "(" ^ string_of_int coordinate.x ^ "," ^ string_of_int coordinate.y ^ ")"
end

module Piece = struct
  type t = X | O [@@deriving yojson]

  let pretty = function
    | Some piece -> ( match piece with X -> "x" | O -> "o")
    | None -> "_"
end

module Player = struct
  type t = string

  let make id = id

  let pretty player = player ^ "\n"
end

module Board = struct
  type t = Piece.t option array array [@@deriving yojson]

  let max_size = 50

  let min_size = 10

  let make size =
    if size > max_size then
      Error (`Board_Size_Too_Big (size, min_size, max_size))
    else if size < min_size then
      Error (`Board_Size_Too_Small (size, min_size, max_size))
    else Ok (Array.make_matrix size size (None : Piece.t option) : t)

  let get_piece ~(coordinate : Coordinate.t) ~(board : t) =
    try board.(coordinate.y).(coordinate.x) with Invalid_argument _ -> None

  let place_piece ~piece ~coordinate ~board =
    try
      let piece' = get_piece ~coordinate ~board in
      match piece' with
      | None ->
          let () = board.(coordinate.y).(coordinate.x) <- Some piece in
          Ok board
      | Some _ -> Error (`Piece_Already_Placed coordinate)
    with Invalid_argument _ -> Error (`Piece_Out_Of_Bounds coordinate)

  let transpose board =
    let size = Array.length board in
    let new_board = make size in

    match new_board with
    | Error (`Board_Size_Too_Small _size) -> board
    | Error (`Board_Size_Too_Big _size) -> board
    | Ok transposed_board ->
        for i = 0 to size - 1 do
          for j = 0 to size - 1 do
            transposed_board.(i).(j) <- board.(j).(i)
          done
        done;

        transposed_board

  let pretty board =
    let pretty_string_of_row row =
      Array.fold_left (fun acc p -> acc ^ Piece.pretty p ^ "|") "|" row ^ "\n"
    in

    Array.map pretty_string_of_row board
    |> Array.fold_left (fun acc s -> acc ^ s) ""
end

module Game = struct
  type t = {
    id : string;
    mutable board : Board.t;
    mutable next_move : string;
    mutable winner : string option;
    player_1 : string;
    player_2 : string;
  }
  [@@deriving yojson]

  let make ~size ~player_1 ~player_2 ~game_id =
    match Board.make size with
    | Error (`Board_Size_Too_Small size) -> Error (`Board_Size_Too_Small size)
    | Error (`Board_Size_Too_Big size) -> Error (`Board_Size_Too_Big size)
    | Ok board ->
        Ok
          {
            id = game_id;
            board;
            player_1;
            player_2;
            winner = None;
            next_move = player_1;
          }

  let piece_of_player ~player ~game =
    if player = game.player_1 then Some Piece.X
    else if player = game.player_2 then Some Piece.O
    else None

  let place_piece ~player ~coordinate ~game =
    if player <> game.next_move then Error (`Player_Not_Next player)
    else
      let board = game.board in

      match piece_of_player ~player ~game with
      | None -> Error (`Player_Not_Part_Of_Game (player, game.id))
      | Some piece -> Board.place_piece ~piece ~coordinate ~board

  let next_move game =
    if game.player_1 = game.next_move then game.player_2 else game.player_1

  let check_win game =
    let string_of_board board =
      let string_of_row row =
        Array.fold_left (fun acc p -> acc ^ Piece.pretty p) "|" row
      in

      (Array.map string_of_row board
      |> Array.fold_left (fun acc s -> acc ^ s) "")
      ^ "|"
    in

    let horizontal_board = string_of_board game.board in
    let vertical_board = game.board |> Board.transpose |> string_of_board in

    Dream.log "%s" horizontal_board;
    Dream.log "%s" vertical_board;

    (* let re1 = Re.Str.regexp "/(?<!x)x{2}(?!x)/" in *)
    (* let re2 = Re.Str.regexp "/(?<!o)o{2}(?!o)/" in *)
    (* let player_1_win = Re.Str.string_match re1 horizontal_board 0 in *)
    (* let player_2_win = Re.Str.string_match re2 horizontal_board 0 in *)

    (* if player_1_win then Some game.player_1 *)
    (* else if player_2_win then Some game.player_2 *)
    (* else None *)
    Some game.player_1

  let pretty game =
    let pretty_id = "Game ID: #" ^ game.id ^ "\n" in
    let pretty_board = Board.pretty game.board in
    let pretty_player_1 = "Player 1: " ^ Player.pretty game.player_1 in
    let pretty_player_2 = "Player 2: " ^ Player.pretty game.player_2 in
    let next_piece =
      piece_of_player ~player:game.next_move ~game |> Piece.pretty
    in
    let pretty_next_move =
      "Next move: " ^ game.next_move ^ " (" ^ next_piece ^ ")\n"
    in

    pretty_id ^ pretty_player_1 ^ pretty_player_2 ^ pretty_board
    ^ pretty_next_move

  let to_json game = game |> yojson_of_t |> Yojson.Safe.to_string
end

(* module Game_Error_Message = struct *)
(*   type error_variants = *)
(*     [> `Piece_Already_Placed of Coordinate.t *)
(*     | `Piece_Out_Of_Bounds of Coordinate.t *)
(*     | `Player_Not_Next of Player.t *)
(*     | `Player_Not_Part_Of_Game of Player.t * string ] *)

(*   type t = { error : error_variants; human_readable_error : string } *)
(*   [@@deriving yojson] *)

(*   let make ~error ~human_error = { error; human_readable_error = human_error } *)

(*   let to_json error = error |> yojson_of_t |> Yojson.Safe.to_string *)

(*   let respond_with_error ~error ~human_error = *)
(*     make ~error ~human_error |> to_json |> Dream.json *)
(* end *)

module Games = Map.Make (String)

module State = struct
  let games = ref Games.empty

  let add_game id game games = Games.add id game games

  let remove_game id games = Games.remove id !games

  let get_game id games = Games.find_opt id !games
end

let new_game request =
  let game_id = Dream.param "game_id" request in
  match State.get_game game_id State.games with
  | None -> (
      try
        let%lwt body = Dream.body request in

        let new_game_body =
          body |> Yojson.Safe.from_string |> new_game_body_of_yojson
        in

        let { player_1; player_2; size } = new_game_body in

        match Game.make ~size ~player_1 ~player_2 ~game_id with
        | Error (`Board_Size_Too_Small (size, min_size, max_size)) ->
            Dream.json
              ("The Board size of the game needs to be between"
             ^ string_of_int min_size ^ " and " ^ string_of_int max_size ^ ", "
             ^ string_of_int size ^ " is too small")
        | Error (`Board_Size_Too_Big (size, min_size, max_size)) ->
            Dream.json
              ("The Board size of the game needs to be between"
             ^ string_of_int min_size ^ " and " ^ string_of_int max_size ^ ", "
             ^ string_of_int size ^ " is too big")
        | Ok new_game ->
            State.games := State.add_game game_id new_game !State.games;
            new_game |> Game.to_json |> Dream.json
      with _ -> Dream.json "Invalid POST data for new_game")
  | Some _game -> Dream.json ("Game with ID #" ^ game_id ^ " already exists")

let end_game request =
  let game_id = Dream.param "game_id" request in
  match State.get_game game_id State.games with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " doest not exist")
  | Some _game ->
      State.games := State.remove_game game_id State.games;
      Dream.empty `OK

let play_game request =
  let game_id = Dream.param "game_id" request in
  let game = State.get_game game_id State.games in
  match game with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " doest not exist")
  | Some game -> (
      try
        let%lwt body = Dream.body request in

        let player_move_body =
          body |> Yojson.Safe.from_string |> player_move_body_of_yojson
        in

        let { player; x; y } = player_move_body in

        let coordinate = Coordinate.make ~x ~y in

        match Game.place_piece ~player ~coordinate ~game with
        | Error (`Player_Not_Next player) ->
            Dream.json ("It's not player " ^ player ^ "s turn")
        | Error (`Player_Not_Part_Of_Game (player, game_id)) ->
            Dream.json
              ("Player " ^ player ^ " is not a part of Game with ID #" ^ game_id)
        | Error (`Piece_Already_Placed coordinate) ->
            Dream.json
              ("Piece on coordinates "
              ^ Coordinate.pretty coordinate
              ^ " has already been placed")
        | Error (`Piece_Out_Of_Bounds coordinate) ->
            Dream.json
              ("Piece on coordinates "
              ^ Coordinate.pretty coordinate
              ^ " would be placed out of bounds")
        | Ok board' ->
            game.board <- board';
            game.next_move <- Game.next_move game;

            let winner = Game.check_win game in
            game.winner <- winner;

            let () =
              match game.winner with
              | Some _ -> State.games := State.remove_game game.id State.games
              | None -> ()
            in

            game |> Game.to_json |> Dream.json
      with _ -> Dream.json "Invalid PUT data for play_game")

let view_game request =
  let game_id = Dream.param "game_id" request in
  let game = State.get_game game_id State.games in
  match game with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " does not exist")
  | Some game -> game |> Game.to_json |> Dream.json

let view_game_pretty request =
  let game_id = Dream.param "game_id" request in
  let game = State.get_game game_id State.games in
  match game with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " does not exist")
  | Some game -> Game.pretty game |> Dream.html

let view_game_pretty_transpose request =
  let game_id = Dream.param "game_id" request in
  let game = State.get_game game_id State.games in
  match game with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " does not exist")
  | Some game ->
      game.board <- Board.transpose game.board;
      Game.pretty game |> Dream.html

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
         Dream.get "/view_game/:game_id/pretty-transpose" (fun request ->
             view_game_pretty_transpose request);
       ]
  @@ Dream.not_found
