open Rresult
open R

type player_move_body = { player : string; x : int; y : int }
[@@deriving of_yojson]

type new_game_body = {
  size : int; [@default 20]
  player_1 : string;
  player_2 : string;
}
[@@deriving of_yojson]

module Coordinate = struct
  type t = { x : int; y : int }

  let make ~x ~y = { x; y }

  let to_string coordinate =
    "(" ^ string_of_int coordinate.x ^ "," ^ string_of_int coordinate.y ^ ")"
end

module Piece = struct
  type t = X | O

  let yojson_of_t = function X -> `String "x" | O -> `String "o"

  let to_string = function X -> "x" | O -> "o"
end

module Player = struct
  type t = string

  let make id = id

  let to_string player = player
end

module Board = struct
  type t = Piece.t option array array [@@deriving yojson_of]

  let max_size = 50

  let min_size = 10

  let make size =
    if size > max_size then
      Error (`Board_Size_Too_Big (size, min_size, max_size))
    else if size < min_size then
      Error (`Board_Size_Too_Small (size, min_size, max_size))
    else Ok (Array.make_matrix size size None)

  let get_piece ~(coordinate : Coordinate.t) ~(board : t) =
    try board.(coordinate.y).(coordinate.x) with _ -> None

  let place_piece ~piece ~coordinate ~board =
    try
      match get_piece ~coordinate ~board with
      | None ->
          let () = board.(coordinate.y).(coordinate.x) <- Some piece in
          Ok board
      | Some _ -> Error (`Piece_Already_Placed coordinate)
    with Invalid_argument _ -> Error (`Piece_Out_Of_Bounds coordinate)

  let transpose ~f ~board = Array.length board |> make >>= fun b -> f b

  let to_string board =
    let string_of_piece = function
      | Some piece -> Piece.to_string piece
      | None -> "_"
    in
    let string_of_row row =
      Array.fold_left (fun acc p -> acc ^ string_of_piece p ^ "|") "|" row
      ^ "\n"
    in

    Array.map string_of_row board |> Array.fold_left (fun acc s -> acc ^ s) ""
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
  [@@deriving yojson_of]

  let make ~size ~player_1 ~player_2 ~game_id =
    let make_aux board =
      Ok
        {
          id = game_id;
          board;
          player_1;
          player_2;
          winner = None;
          next_move = player_1;
        }
    in
    Board.make size >>= make_aux

  let piece_of_player ~player ~game =
    if player = game.player_1 then Ok Piece.X
    else if player = game.player_2 then Ok Piece.O
    else Error (`Player_Not_Part_Of_Game (player, game.id))

  let place_piece ~player ~coordinate ~game =
    if player <> game.next_move then Error (`Player_Not_Next player)
    else
      piece_of_player ~player ~game >>= fun piece ->
      Board.place_piece ~coordinate ~board:game.board ~piece

  let next_move game =
    if game.player_1 = game.next_move then game.player_2 else game.player_1

  let check_win game =
    let board = game.board in
    let length_of_board = Array.length game.board - 1 in

    let append_with_none array_1 array_2 =
      Array.append [| None |] array_2 |> Array.append array_1
    in

    let row_of_board = Array.fold_left append_with_none [||] in

    let row_of_col t_board =
      (* |x|_|_|_|_|    |x|x|x|x|x| *)
      (* |x|_|_|_|_|    |_|_|_|_|_| *)
      (* |x|_|_|_|_| -> |_|_|_|_|_| *)
      (* |x|_|_|_|_|    |_|_|_|_|_| *)
      (* |x|_|_|_|_|    |_|_|_|_|_| *)
      for y = 0 to length_of_board do
        for x = 0 to length_of_board do
          t_board.(y).(x) <- (try board.(x).(y) with _ -> None)
        done
      done;

      Ok t_board
    in

    let row_of_left_diagonal t_board =
      (* |x|_|_|_|_|    |x|x|x|x|x| *)
      (* |_|x|_|_|_|    |_|_|_|_|_| *)
      (* |_|_|x|_|_| -> |_|_|_|_|_| *)
      (* |_|_|_|x|_|    |_|_|_|_|_| *)
      (* |_|_|_|_|x|    |_|_|_|_|_| *)
      for y = 0 to length_of_board do
        for x = 0 to length_of_board do
          t_board.(y).(x) <- (try board.(y + x).(x) with _ -> None)
        done
      done;

      Ok t_board
    in

    let row_of_right_diagonal t_board =
      (* |_|_|_|_|x|    |_|_|_|_|_| *)
      (* |_|-|_|x|_|    |_|_|_|_|_| *)
      (* |_|_|x|_|_| -> |_|_|_|_|_| *)
      (* |_|x|_|_|_|    |_|_|_|_|_| *)
      (* |x|_|_|_|_|    |x|x|x|x|x| *)
      for y = 0 to length_of_board do
        for x = 0 to length_of_board do
          t_board.(x).(y) <- (try board.(x - y).(y) with _ -> None)
        done
      done;

      Ok t_board
    in

    let check_row row =
      let size = Array.length row - 1 in
      let player_1_count = ref 0 in
      let player_1_win = ref false in
      let player_2_count = ref 0 in
      let player_2_win = ref false in

      for i = 0 to size do
        match row.(i) with
        | Some piece -> (
            match piece with
            | Piece.X ->
                player_1_count := !player_1_count + 1;
                player_2_count := 0;
                if !player_2_count = 5 then player_2_win := true
            | Piece.O ->
                player_2_count := !player_2_count + 1;
                player_1_count := 0;
                if !player_1_count = 5 then player_1_win := true)
        | None ->
            if !player_1_count = 5 then player_1_win := true;
            if !player_2_count = 5 then player_2_win := true;
            player_1_count := 0;
            player_2_count := 0
      done;

      if !player_1_win then Some game.player_1
      else if !player_2_win then Some game.player_2
      else None
    in

    let horizontal_board () = row_of_board board in

    let vertical_board () =
      match Board.transpose ~f:row_of_col ~board with
      | Ok b -> row_of_board b
      | _ -> failwith "wtf"
    in

    let right_diagonal_board () =
      match Board.transpose ~f:row_of_right_diagonal ~board with
      | Ok b -> row_of_board b
      | _ -> failwith "wtf"
    in

    let left_diagonal_board () =
      match Board.transpose ~f:row_of_left_diagonal ~board with
      | Ok b -> row_of_board b
      | _ -> failwith "wtf"
    in

    (* eeeh... *)
    match check_row (horizontal_board ()) with
    | Some player -> Some player
    | None -> (
        match check_row (vertical_board ()) with
        | Some player -> Some player
        | None -> (
            match check_row (left_diagonal_board ()) with
            | Some player -> Some player
            | None -> (
                match check_row (right_diagonal_board ()) with
                | Some player -> Some player
                | None -> None)))

  let to_string game =
    let string_of_id = "Game ID: #" ^ game.id ^ "\n" in
    let string_of_board = Board.to_string game.board in
    let string_of_player_1 =
      "Player 1: " ^ Player.to_string game.player_1 ^ "\n"
    in
    let string_of_player_2 =
      "Player 2: " ^ Player.to_string game.player_2 ^ "\n"
    in
    let string_of_next_piece =
      match piece_of_player ~player:game.next_move ~game with
      | Ok piece -> Piece.to_string piece
      | _ -> ""
    in

    let game_info =
      match game.winner with
      | Some player -> "Player " ^ player ^ " has won the game!\n"
      | None ->
          "Next move: " ^ game.next_move ^ " (" ^ string_of_next_piece ^ ")\n"
    in

    string_of_id ^ string_of_player_1 ^ string_of_player_2 ^ string_of_board
    ^ game_info

  let to_json game = game |> yojson_of_t |> Yojson.Safe.to_string
end

module Games = Map.Make (String)

module State = struct
  type t = Game.t Games.t

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
  match State.get_game game_id State.games with
  | None -> Dream.json ("Game with ID #" ^ game_id ^ " doest not exist")
  | Some game -> (
      match game.winner with
      | None -> (
          try
            let%lwt body = Dream.body request in

            let player_move_body =
              body |> Yojson.Safe.from_string |> player_move_body_of_yojson
            in

            let { player; x; y } = player_move_body in

            let coordinate = Coordinate.make ~x ~y in

            match Game.place_piece ~player ~coordinate ~game with
            | Error (`Player_Not_Part_Of_Game (player, game_id)) ->
                Dream.json
                  ("Player " ^ player ^ " is not a part of Game with ID #"
                 ^ game_id)
            | Error (`Player_Not_Next player) ->
                Dream.json ("It's not player " ^ player ^ "s turn")
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
            | Ok board ->
                game.board <- board;
                game.next_move <- Game.next_move game;
                game.winner <- Game.check_win game;

                game |> Game.to_json |> Dream.json
          with _ -> Dream.json "Invalid PUT data for play_game")
      | Some winner ->
          Dream.json
            ("Game with ID #" ^ game.id ^ " has already been won by player "
           ^ winner))

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
       ]
  @@ Dream.not_found
