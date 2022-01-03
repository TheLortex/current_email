(lang dune 2.0)

(generate_opam_files true)

(package
 (name current_email)
 (synopsis "An OCurrent plugin to send emails")
 (description "Publish emails reporting statuses using colombe")
 (depends
  current
  colombe
  sendmail
  (ocaml
   (>= 4.13.0))))
