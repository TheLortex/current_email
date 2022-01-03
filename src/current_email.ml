type any_domain_name = Domain_name_univ : 'a Domain_name.t -> any_domain_name

type ctx = {
  sender : Sendmail.reverse_path;
  authentication : Sendmail.authentication;
  authenticator : X509.Authenticator.t;
  domain : Sendmail.domain;
  hostname : any_domain_name;
  with_starttls : bool;
}

let make ~sender ~authentication ~authenticator ~domain ~hostname ~with_starttls
    =
  {
    sender;
    authenticator;
    authentication;
    domain;
    hostname = Domain_name_univ hostname;
    with_starttls;
  }

module Op = struct
  type t = ctx

  let id = "current-email"

  module Key = struct
    type t = { destination : Sendmail.forward_path; key : string }

    let digest { destination; key } =
      Fmt.str "%a-%s" Colombe.Forward_path.pp destination key
  end

  module Value = struct
    type t = Mrmime.Mt.t

    let digest mail =
      let open Digestif.BLAKE2B in
      let rec consume ctx stream =
        match stream () with
        | None -> ctx
        | Some (buf, off, len) ->
            let ctx = feed_string ctx ~off ~len buf in
            consume ctx stream
      in
      Mrmime.Mt.to_stream mail |> consume (init ()) |> get |> to_hex
  end

  module Outcome = Current.Unit

  let pp f ({ Key.destination; key }, _) =
    Fmt.pf f "To %a: %s" Colombe.Forward_path.pp destination key

  let auto_cancel = false
  let map_stream_to_lwt stream () = Lwt.return (stream ())

  let publish
      {
        sender;
        authenticator;
        authentication;
        domain;
        hostname = Domain_name_univ hostname;
        with_starttls;
      } job { Key.destination; _ } mail =
    let open Lwt.Syntax in
    let mail = Mrmime.Mt.to_stream mail |> map_stream_to_lwt in
    let* () = Current.Job.start ~level:Average job in

    if with_starttls then
      Sendmail_lwt.sendmail_with_starttls ~hostname ~domain ~authenticator
        ~authentication sender [ destination ] mail
      |> Lwt.map
           (Result.map_error (fun err ->
                `Msg (Fmt.to_to_string Sendmail_with_starttls.pp_error err)))
    else
      Sendmail_lwt.sendmail ~hostname ~domain ~authenticator ~authentication
        sender [ destination ] mail
      |> Lwt.map
           (Result.map_error (fun err ->
                `Msg (Fmt.to_to_string Sendmail.pp_error err)))
end

module Sendmail_op = Current_cache.Output (Op)

let send ctx ~destination ~key email =
  let open Current.Syntax in
  Current.component "current-email"
  |> let> key and> destination and> email in
     Sendmail_op.set ctx { destination; key } email
