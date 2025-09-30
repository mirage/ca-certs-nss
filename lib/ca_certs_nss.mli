val authenticator :
  ?time:(unit -> Ptime.t option) ->
  ?crls:X509.CRL.t list ->
  ?allowed_hashes:Digestif.hash' list ->
  unit ->
  (X509.Authenticator.t, [> `Msg of string ]) result
(** [authenticator ~crls ~hash_whitelist ()] is an authenticator with the
    provided revocation lists, hash_whitelist. The trust anchors are based on
    the extraction from NSS' certdata.txt. *)
