open Rresult
open R

module Coordinate = struct
  type t = {
    x : int;
    y : int;
  }

  let make ~x ~y = { x; y }
  let x c = c.x
  let y c = c.y

  let to_string coordinate =
    "("
    ^ string_of_int (x coordinate)
    ^ ","
    ^ string_of_int (y coordinate)
    ^ ")"
end

module Piece = struct
  type t =
    | X
    | O

  let yojson_of_t = function X -> `String "x" | O -> `String "o"
  let to_string = function X -> "x" | O -> "o"
end

module Player = struct
  type t = string [@@deriving yojson_of]

  let make id = id
  let is_equal_to p1 p2 = p1 = p2
  let to_string player = player
end

module Board = struct
  type t = Piece.t option array array [@@deriving yojson_of]

  let max_size = 50
  let min_size = 10

  let make size =
    if size > max_size
    then Error (`Board_Size_Too_Big (size, min_size, max_size))
    else if size < min_size
    then Error (`Board_Size_Too_Small (size, min_size, max_size))
    else Ok (Array.make_matrix ~dimx:size ~dimy:size None)

  let get_piece ~coordinate ~board =
    try Coordinate.(board.(x coordinate).(y coordinate)) with _ -> None

  let place_piece ~piece ~coordinate ~board =
    let y = Coordinate.y coordinate in

    try
      let new_board =
        Array.copy board
        |> fun b ->
        let () = b.(y) <- Array.copy b.(y) in
        b
      in

      match get_piece ~coordinate ~board:new_board with
      | None ->
          let x = Coordinate.x coordinate in
          let () = new_board.(y).(x) <- Some piece in
          Ok new_board
      | Some _ -> Error (`Piece_Already_Placed coordinate)
    with
    | Invalid_argument _ -> Error (`Piece_Out_Of_Bounds coordinate)

  let to_string board =
    let string_of_piece = function
      | Some piece -> Piece.to_string piece
      | None -> "_"
    in

    let string_of_row row =
      Array.fold_left
        ~f:(fun acc p -> acc ^ string_of_piece p ^ "|")
        ~init:"|" row
      ^ "\n"
    in

    Array.map ~f:string_of_row board |> Array.fold_left ~f:( ^ ) ~init:""
end

module Game = struct
  type t = {
    id : string;
    board : Board.t;
    player_1 : Player.t;
    player_2 : Player.t;
    next_move : Player.t;
    winner : Player.t option;
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

  let player_is_part_of_game ~player ~game =
    if Player.(is_equal_to player game.player_1)
       || Player.(is_equal_to player game.player_2)
    then Ok player
    else Error (`Player_Not_Part_Of_Game (player, game.id))

  let piece_of_player ~player ~game =
    if Player.(is_equal_to player game.player_1)
    then Ok Piece.X
    else if Player.(is_equal_to player game.player_2)
    then Ok Piece.O
    else Error (`Player_Not_Part_Of_Game (player, game.id))

  let set_board ~board ~game =
    let new_board_size = Array.length board in
    let old_board_size = Array.length game.board in

    if new_board_size <> old_board_size
    then Error (`Board_Not_Game_Size (new_board_size, old_board_size))
    else Ok { game with board }

  let set_winner ~player ~game =
    player_is_part_of_game ~player ~game
    >>= fun player -> Ok { game with winner = Some player }

  let set_next_move ~player ~game =
    player_is_part_of_game ~player ~game
    >>= fun player -> Ok { game with next_move = player }

  let place_piece ~player ~coordinate ~game =
    if Player.(is_equal_to player game.next_move)
    then
      piece_of_player ~player ~game
      >>= fun piece ->
      Board.place_piece ~piece ~coordinate ~board:game.board
      >>= fun board -> set_board ~board ~game
    else Error (`Player_Not_Next player)

  let next_move game =
    if Player.(is_equal_to game.player_1 game.next_move)
    then game.player_2
    else game.player_1

  let check_win game =
    let board = game.board in
    let length_of_board = Array.length game.board - 1 in

    let append_with_none v1 v2 =
      Array.append [| None |] v2 |> Array.append v1
    in

    let row_of_board = Array.fold_left ~f:append_with_none ~init:[||] in

    let row_of_columns board =
      let new_board = Array.copy board |> Array.copy in
      (* |x|_|_|_|_|    |x|x|x|x|x| *)
      (* |x|_|_|_|_|    |_|_|_|_|_| *)
      (* |x|_|_|_|_| -> |_|_|_|_|_| *)
      (* |x|_|_|_|_|    |_|_|_|_|_| *)
      (* |x|_|_|_|_|    |_|_|_|_|_| *)
      for y = 0 to length_of_board do
        for x = 0 to length_of_board do
          new_board.(y).(x) <- (try board.(x).(y) with _ -> None)
        done
      done;

      row_of_board new_board
    in

    let row_of_left_diagonals board =
      let new_board = Array.copy board |> Array.copy in
      (* |x|_|_|_|_|    |x|x|x|x|x| *)
      (* |_|x|_|_|_|    |_|_|_|_|_| *)
      (* |_|_|x|_|_| -> |_|_|_|_|_| *)
      (* |_|_|_|x|_|    |_|_|_|_|_| *)
      (* |_|_|_|_|x|    |_|_|_|_|_| *)
      for y = 0 to length_of_board do
        for x = 0 to length_of_board do
          new_board.(y).(x) <- (try board.(y + x).(x) with _ -> None)
        done
      done;

      row_of_board new_board
    in

    let row_of_right_diagonals board =
      let new_board = Array.copy board |> Array.copy in
      (* |_|_|_|_|x|    |_|_|_|_|_| *)
      (* |_|-|_|x|_|    |_|_|_|_|_| *)
      (* |_|_|x|_|_| -> |_|_|_|_|_| *)
      (* |_|x|_|_|_|    |_|_|_|_|_| *)
      (* |x|_|_|_|_|    |x|x|x|x|x| *)
      for y = 0 to length_of_board do
        for x = 0 to length_of_board do
          new_board.(x).(y) <- (try board.(x - y).(y) with _ -> None)
        done
      done;

      row_of_board new_board
    in

    let check_row row =
      let size = Array.length row - 1 in

      let rec check_row_aux ~i ~p1 ~p2 =
        if i < size
        then
          match row.(i) with
          | Some piece -> (
              match piece with
              | Piece.X ->
                  if p2 = 5
                  then Some `Player_2_Win
                  else check_row_aux ~i:(i + 1) ~p1:(p1 + 1) ~p2:0
              | Piece.O ->
                  if p1 = 5
                  then Some `Player_1_Win
                  else check_row_aux ~i:(i + 1) ~p2:(p2 + 1) ~p1:0)
          | None ->
              if p1 = 5
              then Some `Player_1_Win
              else if p2 = 5
              then Some `Player_2_Win
              else check_row_aux ~i:(i + 1) ~p1:0 ~p2:0
        else None
      in

      check_row_aux ~i:0 ~p1:0 ~p2:0
    in

    let check_draw board =
      let keep_none = function Some _ -> false | None -> true in

      let number_of_empty_coordinates =
        Array.fold_left ~f:Array.append ~init:[||] board
        |> Array.to_list
        |> List.filter ~f:keep_none
        |> List.length
      in

      if number_of_empty_coordinates = 0 then Some `Draw else None
    in

    let map_none b a = match a with Some _ -> a | None -> b () in

    check_row (row_of_board board)
    |> map_none (fun () -> board |> row_of_columns |> check_row)
    |> map_none (fun () -> board |> row_of_left_diagonals |> check_row)
    |> map_none (fun () -> board |> row_of_right_diagonals |> check_row)
    |> map_none (fun () -> check_draw board)

  let play_game ~player ~coordinate ~game =
    place_piece ~player ~coordinate ~game
    >>= fun game ->
    match check_win game with
    | None -> set_next_move ~player:(next_move game) ~game
    | Some `Player_1_Win -> set_winner ~player:game.player_1 ~game
    | Some `Player_2_Win -> set_winner ~player:game.player_2 ~game
    | Some `Draw -> Ok game

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
      | Error _ -> ""
    in

    let game_info =
      match game.winner with
      | Some player -> "Player " ^ player ^ " has won the game!\n"
      | None ->
          "Next move: " ^ game.next_move ^ " (" ^ string_of_next_piece ^ ")\n"
    in

    string_of_id
    ^ string_of_player_1
    ^ string_of_player_2
    ^ string_of_board
    ^ game_info

  let to_json game = game |> yojson_of_t |> Yojson.Safe.to_string
end
