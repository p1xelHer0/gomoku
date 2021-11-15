module Games : Map.S with type key = string

module State : sig
  type t

  val games : t ref

  val add_game : string -> Gomoku.Game.t -> t -> t

  val remove_game : string -> t -> t

  val get_game : string -> t -> Gomoku.Game.t option
end
