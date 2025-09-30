let nsec_per_day = 86_400 * 1_000_000_000
and ps_per_ns = 1_000L

let time () =
  let nsec = Mkernel.clock_wall () in
  let days = nsec / nsec_per_day in
  let rem_ns = nsec mod nsec_per_day in
  let rem_ps = Int64.mul (Int64.of_int rem_ns) ps_per_ns in
  Some (Ptime.v (days, rem_ps))

let authenticator ?(time = time) =
  let tas =
    List.fold_left
      (fun acc data ->
        Result.bind acc (fun acc ->
            Result.map
              (fun cert -> cert :: acc)
              (X509.Certificate.decode_der data)))
      (Ok []) Trust_anchor.certificates
  in
  fun ?crls ?allowed_hashes () ->
    Result.map
      (X509.Authenticator.chain_of_trust ~time ?crls ?allowed_hashes)
      tas
