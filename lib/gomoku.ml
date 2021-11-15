open Rresult
open R

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
    else Ok (Array.make_matrix ~dimx:size ~dimy:size None)

  let get_piece ~(coordinate : Coordinate.t) ~board =
    try Coordinate.(board.(coordinate.y).(coordinate.x)) with _ -> None

  let place_piece ~piece ~coordinate ~board =
    try
      match get_piece ~coordinate ~board with
      | None ->
          let () =
            Coordinate.(board.(coordinate.y).(coordinate.x) <- Some piece)
          in
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
      Array.fold_left
        ~f:(fun acc p -> acc ^ string_of_piece p ^ "|")
        ~init:"|" row
      ^ "\n"
    in

    Array.map ~f:string_of_row board
    |> Array.fold_left ~f:(fun acc s -> acc ^ s) ~init:""
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

    let row_of_board = Array.fold_left ~f:append_with_none ~init:[||] in

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

      let rec check_row_aux ~i ~p1 ~p2 =
        if i < size then
          match row.(i) with
          | Some piece -> (
              match piece with
              | Piece.X ->
                  if p2 = 5 then Some game.player_2
                  else check_row_aux ~i:(i + 1) ~p1:(p1 + 1) ~p2:0
              | Piece.O ->
                  if p1 = 5 then Some game.player_1
                  else check_row_aux ~i:(i + 1) ~p2:(p2 + 1) ~p1:0)
          | None ->
              if p1 = 5 then Some game.player_1
              else if p2 = 5 then Some game.player_2
              else check_row_aux ~i:(i + 1) ~p1:0 ~p2:0
        else None
      in

      check_row_aux ~i:0 ~p1:0 ~p2:0
    in

    let horizontal_board () = row_of_board board in

    let vertical_board () =
      match Board.transpose ~f:row_of_col ~board with
      | Ok b -> row_of_board b
      | Error _ -> failwith "wtf"
    in

    let right_diagonal_board () =
      match Board.transpose ~f:row_of_right_diagonal ~board with
      | Ok b -> row_of_board b
      | Error _ -> failwith "wtf"
    in

    let left_diagonal_board () =
      match Board.transpose ~f:row_of_left_diagonal ~board with
      | Ok b -> row_of_board b
      | Error _ -> failwith "wtf"
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
      | Error _ -> ""
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
