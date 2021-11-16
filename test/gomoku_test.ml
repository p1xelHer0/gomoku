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

let suite =
  [
    ("Coordinate", `Quick, test_coordinate);
    ("Piece", `Quick, test_piece);
    ("Player", `Quick, test_player);
  ]

let () = Alcotest.run "Gomoku" [ ("Gomoku tests", suite) ]
