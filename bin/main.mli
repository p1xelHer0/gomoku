type new_game_body
(** Contains data for a new game. *)

type player_move_body
(** Contains data for a player move. *)

val parse_new_game : string -> new_game_body
(** Parses the JSON body recieved from the client containing data for a new 
    game. *)

val parse_player_move : string -> player_move_body
(** Parses the JSON body recieved from the client containing data for a player 
    move. *)

module Games : Map.S with type key = string

module State : sig
  type t
  (**  Describes how to store the games. *)

  val games : t ref
  (** Holds the running games. *)

  val add_game : string -> Gomoku.Game.t -> t -> t
  (** [add_game game_id game games] returns [t] containing the newly added 
      [game]. *)

  val remove_game : string -> t -> t
  (** [add_game game_id game games] returns [t] without the newly removed 
      [game]. *)

  val get_game : string -> t -> Gomoku.Game.t option
  (**  [get_game game_id games] returns [Some game] if the game exists in 
       [games]. *)
end

val new_game : Dream.request -> Dream.response Lwt.t
(** [new_game request] lets the client start a new game. *)

val play_game : Dream.request -> Dream.response Lwt.t
(** [play_game request] lets the client play on an existing game. *)

val end_game : Dream.request -> Dream.response Lwt.t
(** [end_game request] lets the client end an existing game. *)

val view_game : Dream.request -> Dream.response Lwt.t
(** [view_game request] lets the client view and existing game. *)

val view_game_pretty : Dream.request -> Dream.response Lwt.t
(** [view_game_pretty request] lets the client view an existing game in a
    human viewable ASCII art form. *)

val view_all_games : Dream.request -> Dream.response Lwt.t
(** [view_all_games request] lets the client view all existing games. *)
