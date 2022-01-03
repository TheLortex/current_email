type ctx = Letters.Config.t

module Cmdline = struct
  open Cmdliner

  let maybe fn value t = match value with None -> t | Some value -> fn value t

  let make config_file =
    let json = Yojson.Safe.from_file config_file in
    let open Yojson.Safe.Util in
    let username = json |> member "username" |> to_string in
    let password = json |> member "password" |> to_string in
    let hostname = json |> member "hostname" |> to_string in
    let with_starttls = json |> member "starttls" |> to_bool in
    let ca_cert = json |> member "ca_cert" |> to_string_option in
    let ca_path = json |> member "ca_path" |> to_string_option in
    let port = json |> member "port" |> to_int_option in
    Letters.Config.make ~username ~password ~hostname ~with_starttls
    |> maybe Letters.Config.set_ca_cert ca_cert
    |> maybe Letters.Config.set_ca_path ca_path
    |> Letters.Config.set_port port

  let make_opt = Option.map make

  let config_file =
    Arg.value
    @@ Arg.opt Arg.(some string) None
    @@ Arg.info ~doc:"SMTP configuration file" ~docv:"SMTP_CONFIG_FILE"
         [ "smtp-config-file" ]

  let v_opt = Term.(const make_opt $ config_file)

  let config_file_req =
    Arg.required
    @@ Arg.opt Arg.(some string) None
    @@ Arg.info ~doc:"SMTP configuration file" ~docv:"SMTP_CONFIG_FILE"
         [ "smtp-config-file" ]

  let v = Term.(const make $ config_file_req)
end

let cmdliner = Cmdline.v
let cmdliner_opt = Cmdline.v_opt

module Op = struct
  type t = { config : Letters.Config.t; sender : string }

  let id = "current-email"

  module Key = struct
    type t = { recipient : string; key : string }

    let digest { recipient; key } = Fmt.str "%s-%s" recipient key
  end

  module Value = struct
    type t = { message : Mrmime.Mt.t; digest : string }

    let digest { digest; _ } = digest
  end

  module Outcome = Current.Unit

  let pp f ({ Key.recipient; key }, { Value.digest; _ }) =
    Fmt.pf f "To %s: %s\nMessage digest:%s" recipient key digest

  let auto_cancel = false

  let publish { sender; config } job { Key.recipient; _ } { Value.message; _ } =
    let open Lwt.Syntax in
    let* () = Current.Job.start ~level:Average job in
    Lwt.catch
      (fun () ->
        Letters.send ~config ~sender ~recipients:[ To recipient ] ~message
        |> Lwt.map Result.ok)
      (function
        | Stdlib.Failure msg -> Lwt.return (Error (`Msg msg)) | exn -> raise exn)
end

module Sendmail_op = Current_cache.Output (Op)

type message = Op.Value.t

let make digest message = {Op.Value.digest; message}

let send config ~sender ~recipient ~key message =
  let open Current.Syntax in
  Current.component "current-email"
  |> let> key and> recipient and> message and> sender in
     Sendmail_op.set { config; sender } { recipient; key } message
