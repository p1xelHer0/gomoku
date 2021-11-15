module Coordinate : sig
  type t = { x : int; y : int }

  val make : x:int -> y:int -> t

  val to_string : t -> string
end

module Piece : sig
  type t

  val to_string : t -> string
end

module Player : sig
  type t

  val make : string -> t

  val to_string : t -> string
end

module Board : sig
  type t

  val max_size : int

  val min_size : int

  val make :
    int ->
    ( t,
      [> `Board_Size_Too_Big of int * int * int
      | `Board_Size_Too_Small of int * int * int ] )
    result

  val get_piece : coordinate:Coordinate.t -> board:t -> Piece.t option

  val place_piece :
    piece:Piece.t ->
    coordinate:Coordinate.t ->
    board:t ->
    ( t,
      [> `Piece_Already_Placed of Coordinate.t
      | `Piece_Out_Of_Bounds of Coordinate.t ] )
    result

  val transpose :
    f:
      (t ->
      ( 'a,
        ([> `Board_Size_Too_Big of int * int * int
         | `Board_Size_Too_Small of int * int * int ]
         as
         'b) )
      result) ->
    board:'c array ->
    ('a, 'b) result

  val to_string : t -> string
end

module Game : sig
  type t = {
    id : string;
    mutable board : Board.t;
    mutable next_move : string;
    mutable winner : string option;
    player_1 : string;
    player_2 : string;
  }

  val make :
    size:int ->
    player_1:Player.t ->
    player_2:Player.t ->
    game_id:string ->
    ( t,
      [> `Board_Size_Too_Big of int * int * int
      | `Board_Size_Too_Small of int * int * int ] )
    result

  val piece_of_player :
    player:string ->
    game:t ->
    (Piece.t, [> `Player_Not_Part_Of_Game of string * string ]) result

  val place_piece :
    player:Player.t ->
    coordinate:Coordinate.t ->
    game:t ->
    ( Board.t,
      [> `Piece_Already_Placed of Coordinate.t
      | `Piece_Out_Of_Bounds of Coordinate.t
      | `Player_Not_Next of Player.t
      | `Player_Not_Part_Of_Game of Player.t * string ] )
    result

  val next_move : t -> string

  val check_win : t -> string option

  val to_string : t -> string

  val to_json : t -> string
end