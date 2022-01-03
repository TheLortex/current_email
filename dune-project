(lang dune 2.0)

(generate_opam_files true)

(package
 (name current_email)
 (synopsis "An OCurrent plugin to send emails")
 (description "Publish emails reporting statuses using colombe")
 (depends
  (current
   (>= 0.5))
  (letters
   (>= 0.3.0))
  cmdliner
  yojson
  digestif
  (ocaml
   (>= 4.13.0))
  (current_web :with-test)))
