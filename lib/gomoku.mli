module Coordinate : sig
  type t = { x : int; y : int }
  (** A coordinate. *)

  val make : x:int -> y:int -> t
  (** [make x y] returns a new coordinate. *)

  val to_string : t -> string
  (** [to_string] returns [t] in a human readable format. *)
end

module Piece : sig
  type t = X | O  (** A piece to place on a [Board.t]. *)

  val to_string : t -> string
  (** [to_string] returns [t] in a human readable format. *)
end

module Player : sig
  type t
  (** A player. *)

  val make : string -> t
  (** [make string] returns a new player. *)

  val to_string : t -> string
  (** [to_string] returns [t] in a human readable format. *)
end

module Board : sig
  type t
  (** A board to place [Piece.t] on. *)

  val max_size : int
  (** The maximum size a board can have. *)

  val min_size : int
  (** The minimum size a board can have. *)

  val make :
    int ->
    ( t,
      [> `Board_Size_Too_Big of int * int * int
      | `Board_Size_Too_Small of int * int * int ] )
    result
  (** [make size] returns a [Ok t] if the board is between the [min_size] and 
      [max_size].

      Returns [Error (`Board_Size_Too_Big (size, min_size, max_size))]
      if the size is too big.

      Returns [Error (`Board_Size_Too_Small (size, min_size, max_size))]
      if the size is too small. *)

  val get_piece : coordinate:Coordinate.t -> board:t -> Piece.t option
  (** [get_piece coordinate board] returns [Some Piece.t] if a piece has been 
      placed on [coordinate] of the [board]. *)

  val place_piece :
    piece:Piece.t ->
    coordinate:Coordinate.t ->
    board:t ->
    ( t,
      [> `Piece_Already_Placed of Coordinate.t
      | `Piece_Out_Of_Bounds of Coordinate.t ] )
    result
  (** [place_piece piece coordinate board] attempts to create a new [t]
      by placing a [piece] on [t] at the [coordinate].

      Returns [Ok t] if the [piece] is placed on an empty [coordinate] within
      the [t]. 

      Returns [Error (`Piece_Already_Placed coordinate)] if the [coordinate] on 
      the [t] is not empty.

      Returns [Error (`Piece_Out_Of_Bounds coordinate)] if the [coordinate] is 
      outside of the [t]. *)

  val to_string : t -> string
  (** [to_string] returns [t] in a human readable format. *)
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
  (** A game of Gomoku being played on a [Board.t] between two players. *)

  val make :
    size:int ->
    player_1:Player.t ->
    player_2:Player.t ->
    game_id:string ->
    ( t,
      [> `Board_Size_Too_Big of int * int * int
      | `Board_Size_Too_Small of int * int * int ] )
    result
  (** [make size player_1 player_2 game_id] returns a [Ok t] if the game is 
      between the [min_size] and [max_size] and if both players have difference 
      names. 

      Returns [Error (`Board_Size_Too_Big (size, min_size, max_size))]
      if the size is too big.

      Returns [Error (`Board_Size_Too_Small (size, min_size, max_size))]
      if the size is too small.

      Returns [Error (`Names_Not_Unique name)] if the player names are the same 
      *)

  val piece_of_player :
    player:string ->
    game:t ->
    (Piece.t, [> `Player_Not_Part_Of_Game of string * string ]) result
  (** [piece_of_player player game] returns the assigned [Piece.t] of [player] 
      in the [game]. *)

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
  (** [place_piece player coordinate game] attempts to create a new [Board.t]
      by placing a piece assigned to the [player] on [board] at the 
      [coordinate].

      Returns [Ok Board.t] if it's the [player] turn to play, the 
      [coordinate] is empty and within the [Board.t].

      Returns [Error (`Piece_Already_Placed coordinate)] if the [coordinate] on 
      the [Board.t] is not empty.

      Returns [Error (`Piece_Out_Of_Bounds coordinate)] if the [coordinate] is 
      outside of the [Board.t].

      Returns [Error (`Player_Not_Part_Of_Game (player_id, game_id))] if the 
      [player] is not part of the [game].

      Returns [Error (`Player_NotNext player)] if it's not the [player]s turn 
      to play in the [game]. *)

  val next_move : t -> string
  (** [to_string] returns [t] in a human readable format. *)

  val check_win : t -> string option
  (** [check_win t] returns [Some string] with the player_id if there is a
      winner in the current [t]. *)

  val to_string : t -> string
  (** [to_string] returns [t] in a human readable format. *)

  val to_json : t -> string
  (** [to_json] returns [t] in a json format. *)
end
