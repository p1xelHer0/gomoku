open Gomoku

let test_coordinate () =
  Alcotest.(check string)
    "to_string" "(3,4)"
    (Coordinate.make ~x:3 ~y:4 |> Coordinate.to_string)

let test_piece () =
  Alcotest.(check string) "to_string" "x" (Piece.X |> Piece.to_string);
  Alcotest.(check string) "to_string" "o" (Piece.O |> Piece.to_string)

let test_player () =
  Alcotest.(check string) "to_string" "p1" (Player.make "p1" |> Player.to_string)

let test_game () =
  let player_1 = Player.make "p1" in
  let player_2 = Player.make "p2" in
  let game_id = "123" in
  let size = 20 in
  match Game.make ~size ~player_1 ~player_2 ~game_id with
  | Error _ -> failwith "Game.make Error"
  | Ok original_game -> (
      let open Game in
      let coordinate = Coordinate.make ~x:0 ~y:0 in

      (* Get piece on coordinate (0,0) in original_game. *)
      let piece_1 = Board.get_piece ~coordinate ~board:original_game.board in

      (* Play a round, placing a piece on coordinate (0,0).
         This should return a new [Game.t], not mutate the [original_game]. *)
      match Game.play_game ~player:player_1 ~coordinate ~game:original_game with
      | Error _ -> failwith "Game.play_game Error"
      | Ok _game ->
          (* Get piece on coordinate (0,0) in original_game, again, should be
             the same. *)
          let piece_2 =
            Board.get_piece ~coordinate ~board:original_game.board
          in

          Alcotest.(check bool) "don't mutate original" true (piece_1 = piece_2)
      )

let suite =
  [
    ("Coordinate", `Quick, test_coordinate);
    ("Piece", `Quick, test_piece);
    ("Player", `Quick, test_player);
    ("Game", `Quick, test_game);
  ]

let () = Alcotest.run "Gomoku" [ ("Gomoku tests", suite) ]
