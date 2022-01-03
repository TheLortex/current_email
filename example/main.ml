let email =
  Letters.build_email ~from:"OCaml CI <ci@localhost>"
    ~recipients:[ To "robert@example.com" ]
    ~subject:"This is a test email"
    ~body:(Plain {|
    Hi.
    This is an example email.
    |})
  |> function
  | Ok v -> v
  | Error msg -> failwith msg

let pipeline smtp_config () =
  Current_email.send smtp_config
    ~sender:(Current.return "ci@localhost")
    ~recipient:(Current.return "robert@example.com")
    ~key:(Current.return "")
    (Current.return (Current_email.make "dummy-digest" email))

let main config mode smtp_config =
  Lwt_main.run
  @@
  let engine = Current.Engine.create ~config (pipeline smtp_config) in
  let site =
    Current_web.Site.v ~name:"example-ci"
      ~has_role:(fun _ _ -> true)
      (Current_web.routes engine)
  in
  Lwt.choose [ Current.Engine.thread engine; Current_web.run ~mode site ]

open Cmdliner

let cmd =
  ( Term.(
      term_result
        (const main $ Current.Config.cmdliner $ Current_web.cmdliner
       $ Current_email.cmdliner)),
    Term.info "example-ci" )

let () = Term.(exit @@ eval cmd)
