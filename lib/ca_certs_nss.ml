let authenticator =
  let tas =
    List.fold_left
      (fun acc data ->
        Result.bind acc (fun acc ->
            Result.map
              (fun cert -> cert :: acc)
              (X509.Certificate.decode_der data)))
      (Ok []) Trust_anchor.certificates
  and time () = Some (Mirage_ptime.now ()) in
  fun ?crls ?allowed_hashes () ->
    Result.map
      (X509.Authenticator.chain_of_trust ~time ?crls ?allowed_hashes)
      tas
