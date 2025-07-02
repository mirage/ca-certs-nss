val trust_anchors : (X509.Certificate.t list, [> `Msg of string ]) result
(** [trust_anchors] are the trust anchors extracted from NSS certdata.txt. *)

val authenticator :
  ?crls:X509.CRL.t list ->
  ?allowed_hashes:Digestif.hash' list ->
  unit ->
  (X509.Authenticator.t, [> `Msg of string ]) result
(** [authenticator ~crls ~hash_whitelist ()] is an authenticator with the
    provided revocation lists, and allowed_hashes. The trust anchors are based
    on the extraction from NSS' certdata.txt. *)
