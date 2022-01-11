## Current-email

An _ocurrent_ plugin to send email notifications.

### Introduction

This work relies on [`letters`](https://github.com/oxidizing/letters) for the high-level abstractions, which in turn is based on the [`colombe`](https://github.com/mirage/colombe) project.

Here is a small ocurrent plugin that can be used to automatically send emails when something has changed, for example in a CI system.

### TODO

* Rate limiting / batch updates to avoid spamming

### Testing

Installation:
```
git clone https://github.com/TheLortex/current_email
cd current_email
opam install --deps-only .
```

Obtain a free account on _ethereal.email_, a service that can be used to test SMTP clients:
```
curl -s -d '{ "requestor": "current_email", "version": "dev" }' "https://api.nodemailer.com/user" -X POST -H "Content-Type: application/json" | jq '{ hostname: .smtp.host, port: .smtp.port, starttls: true, username: .user, password: .pass, }'> ethereal_account.json
```

Run the example CI (accessible at http://localhost:8080):
```
dune exec -- example/main.exe --smtp-config-file ethereal_account.json
```
The box should be green, and an email should be visible on the [ethereal.email/login](ethereal.email) platform.

### Configuration file

`Current_email.cmdliner` provides a term that requires a file path: it parses that file as JSON and outputs a `Letters.Config.t` value to use while sending emails.

```
{
  "hostname": "hostname of the SMTP server",
  "starttls": true, /* use STARTTLS */
  "username": "username for the login",
  "password": "password for the login",
  "ca_cert": "use the specified certificate to verify the server",
  "ca_path": "use a directory of certificates to verify the server",
  "port": 587 /* SMTP server port */
}
```

### Acknowledgement

`current_email` has received funding from the Next Generation Internet Initiative (NGI) within the framework of the DAPSI Project
