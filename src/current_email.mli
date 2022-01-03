type ctx

val make :
  sender:Sendmail.reverse_path ->
  authentication:Sendmail.authentication ->
  authenticator:X509.Authenticator.t ->
  domain:Sendmail.domain ->
  hostname:'a Domain_name.t ->
  with_starttls:bool ->
  ctx

val send :
  ctx ->
  destination:Sendmail.forward_path Current.t ->
  key:string Current.t ->
  Mrmime.Mt.t Current.t ->
  unit Current.t
