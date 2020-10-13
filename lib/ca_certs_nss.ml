module Make (C : Mirage_clock.PCLOCK) = struct
  open Rresult.R.Infix

  let authenticator ?crls ?hash_whitelist () =
    List.fold_left
      (fun acc data ->
        acc >>= fun acc ->
        X509.Certificate.decode_der (Cstruct.of_string data) >>| fun cert ->
        cert :: acc)
      (Ok []) Trust_anchor.certificates
    >>| fun tas ->
    let time () = Some (Ptime.v (C.now_d_ps ())) in
    X509.Authenticator.chain_of_trust ~time ?crls ?hash_whitelist tas
end
