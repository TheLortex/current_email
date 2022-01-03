type ctx = Letters.Config.t

val cmdliner : ctx Cmdliner.Term.t
val cmdliner_opt : ctx option Cmdliner.Term.t

type message

val make : string -> Mrmime.Mt.t -> message

val send :
  ctx ->
  sender:string Current.t ->
  recipient:string Current.t ->
  key:string Current.t ->
  message Current.t ->
  unit Current.t
