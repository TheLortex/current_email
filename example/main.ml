let hostname = Domain_name.of_string_exn "osau.re"
let domain = Colombe.Domain.of_string_exn (Unix.gethostname ())
let authenticator ?ip:_ ~host:_ _ = Ok None

let authentication =
  {
    Sendmail.mechanism = Sendmail.PLAIN;
    username = "login";
    password = "password";
  }

let sender =
  let open Mrmime.Mailbox in
  let v =
    Local.[ w "pierre"; w "dubuc" ] @ Domain.(domain, [ a "osau"; a "re" ])
  in
  Result.get_ok (Colombe_emile.to_reverse_path v)
(* "pierre.dubuc@osau.re" *)

let ctx =
  Current_email.make ~sender ~hostname ~authenticator ~authentication ~domain
    ~with_starttls:false

let destination =
  let open Mrmime.Mailbox in
  let v = Local.[ w "to"; w "joe" ] @ Domain.(domain, [ a "gmail"; a "com" ]) in
  Result.get_ok (Colombe_emile.to_forward_path v)
(* "to.joe@gmail.com" *)

let email =
  let open Mrmime.Mt in
  make Mrmime.Header.empty simple (part (fun () -> None))

let pipeline () =
  Current_email.send ctx
    ~destination:(Current.return destination)
    ~key:(Current.return "") (Current.return email)

let main config mode =
  Lwt_main.run
  @@
  let engine = Current.Engine.create ~config pipeline in
  let site =
    Current_web.Site.v ~name:"example-ci"
      ~has_role:(fun _ _ -> true)
      (Current_web.routes engine)
  in
  Lwt.choose [ Current.Engine.thread engine; Current_web.run ~mode site ]

open Cmdliner

let cmd =
  ( Term.(
      term_result (const main $ Current.Config.cmdliner $ Current_web.cmdliner)),
    Term.info "example-ci" )

let () = Term.(exit @@ eval cmd)
