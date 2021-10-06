(* How to add a new test?
   Execute for a host of interest h:
   "echo foo | openssl s_client -connect h:443 -showcerts -no_ticket > out.txt"
   let h_data = {|M-x insert-file out.txt|}
   Add <h, h_data> either to ok_tests or to err_tests (the expected error is required)

   Please note:
   - now is set to a static date (below, can be set to other dates in individual tests)
   - there's no revocation checks
*)
module Clock_2020_10_11 = struct
  let now_d_ps () =
    match Ptime.of_date_time ((2020, 10, 11), ((16, 00, 00), 00)) with
    | None -> assert false
    | Some t -> Ptime.(Span.to_d_ps (to_span t))

  let current_tz_offset_s () = None

  let period_d_ps () = None
end

module TA_2020_10_11 = Ca_certs_nss.Make (Clock_2020_10_11)

let default_auth = Result.get_ok (TA_2020_10_11.authenticator ())

let now = Ptime.v (Clock_2020_10_11.now_d_ps ())

module Clock_2020_05_30 = struct
  let now_d_ps () =
    match Ptime.of_date_time ((2020, 05, 30), ((16, 00, 00), 00)) with
    | None -> assert false
    | Some t -> Ptime.(Span.to_d_ps (to_span t))

  let current_tz_offset_s () = None

  let period_d_ps () = None
end

module TA_2020_05_30 = Ca_certs_nss.Make (Clock_2020_05_30)

let auth_2020_05_30 = Result.get_ok (TA_2020_05_30.authenticator ())

let err =
  let module M = struct
    type t = X509.Validation.validation_error

    let pp = X509.Validation.pp_validation_error

    let equal a b = compare a b = 0 (* TODO relies on polymorphic equality *)
  end in
  (module M : Alcotest.TESTABLE with type t = M.t)

let ok =
  let module M = struct
    type t = (X509.Certificate.t list * X509.Certificate.t) option

    let pp ppf = function
      | None -> Fmt.string ppf "none"
      | Some (chain, _) ->
          Fmt.(list ~sep:(unit ", ") X509.Certificate.pp) ppf chain

    let equal a b =
      match (a, b) with
      | None, None -> true
      | Some (a, _), Some (b, _) ->
          compare a b = 0 (* TODO relies on polymorphic equality *)
      | _ -> false
  end in
  (module M : Alcotest.TESTABLE with type t = M.t)

let r = Alcotest.result ok err

let test_one ta result host chain () =
  let name = Domain_name.to_string host and host = Some host in
  Alcotest.check r ("test one " ^ name) result (ta ~host chain)

let google =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:C = US, ST = California, L = Mountain View, O = Google LLC, CN = *.google.com
   i:C = US, O = Google Trust Services, CN = GTS CA 1O1
-----BEGIN CERTIFICATE-----
MIIJcTCCCFmgAwIBAgIRAOzqbxiPVrFyAgAAAAB8NQswDQYJKoZIhvcNAQELBQAw
QjELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFUdvb2dsZSBUcnVzdCBTZXJ2aWNlczET
MBEGA1UEAxMKR1RTIENBIDFPMTAeFw0yMDA5MjIxNTIyMTlaFw0yMDEyMTUxNTIy
MTlaMGYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQH
Ew1Nb3VudGFpbiBWaWV3MRMwEQYDVQQKEwpHb29nbGUgTExDMRUwEwYDVQQDDAwq
Lmdvb2dsZS5jb20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARomdmWq6BlO0yH
z9Xb08PTWbhcMw4YF14cQRiDKnigLYp3bGxUCDtu5dAdccM0mqQdzK0cMnYMXqEC
2T3Hw647o4IHBzCCBwMwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
BwMBMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFEN+puKWN1FY2tdecjOJANtw/Sak
MB8GA1UdIwQYMBaAFJjR+G4Q68+b7GCfGJAboOt9Cf0rMGgGCCsGAQUFBwEBBFww
WjArBggrBgEFBQcwAYYfaHR0cDovL29jc3AucGtpLmdvb2cvZ3RzMW8xY29yZTAr
BggrBgEFBQcwAoYfaHR0cDovL3BraS5nb29nL2dzcjIvR1RTMU8xLmNydDCCBMIG
A1UdEQSCBLkwggS1ggwqLmdvb2dsZS5jb22CDSouYW5kcm9pZC5jb22CFiouYXBw
ZW5naW5lLmdvb2dsZS5jb22CCSouYmRuLmRldoISKi5jbG91ZC5nb29nbGUuY29t
ghgqLmNyb3dkc291cmNlLmdvb2dsZS5jb22CGCouZGF0YWNvbXB1dGUuZ29vZ2xl
LmNvbYIGKi5nLmNvgg4qLmdjcC5ndnQyLmNvbYIRKi5nY3BjZG4uZ3Z0MS5jb22C
CiouZ2dwaHQuY26CDiouZ2tlY25hcHBzLmNughYqLmdvb2dsZS1hbmFseXRpY3Mu
Y29tggsqLmdvb2dsZS5jYYILKi5nb29nbGUuY2yCDiouZ29vZ2xlLmNvLmlugg4q
Lmdvb2dsZS5jby5qcIIOKi5nb29nbGUuY28udWuCDyouZ29vZ2xlLmNvbS5hcoIP
Ki5nb29nbGUuY29tLmF1gg8qLmdvb2dsZS5jb20uYnKCDyouZ29vZ2xlLmNvbS5j
b4IPKi5nb29nbGUuY29tLm14gg8qLmdvb2dsZS5jb20udHKCDyouZ29vZ2xlLmNv
bS52boILKi5nb29nbGUuZGWCCyouZ29vZ2xlLmVzggsqLmdvb2dsZS5mcoILKi5n
b29nbGUuaHWCCyouZ29vZ2xlLml0ggsqLmdvb2dsZS5ubIILKi5nb29nbGUucGyC
CyouZ29vZ2xlLnB0ghIqLmdvb2dsZWFkYXBpcy5jb22CDyouZ29vZ2xlYXBpcy5j
boIRKi5nb29nbGVjbmFwcHMuY26CFCouZ29vZ2xlY29tbWVyY2UuY29tghEqLmdv
b2dsZXZpZGVvLmNvbYIMKi5nc3RhdGljLmNugg0qLmdzdGF0aWMuY29tghIqLmdz
dGF0aWNjbmFwcHMuY26CCiouZ3Z0MS5jb22CCiouZ3Z0Mi5jb22CFCoubWV0cmlj
LmdzdGF0aWMuY29tggwqLnVyY2hpbi5jb22CECoudXJsLmdvb2dsZS5jb22CEyou
d2Vhci5na2VjbmFwcHMuY26CFioueW91dHViZS1ub2Nvb2tpZS5jb22CDSoueW91
dHViZS5jb22CFioueW91dHViZWVkdWNhdGlvbi5jb22CESoueW91dHViZWtpZHMu
Y29tggcqLnl0LmJlggsqLnl0aW1nLmNvbYIaYW5kcm9pZC5jbGllbnRzLmdvb2ds
ZS5jb22CC2FuZHJvaWQuY29tghtkZXZlbG9wZXIuYW5kcm9pZC5nb29nbGUuY26C
HGRldmVsb3BlcnMuYW5kcm9pZC5nb29nbGUuY26CBGcuY2+CCGdncGh0LmNuggxn
a2VjbmFwcHMuY26CBmdvby5nbIIUZ29vZ2xlLWFuYWx5dGljcy5jb22CCmdvb2ds
ZS5jb22CD2dvb2dsZWNuYXBwcy5jboISZ29vZ2xlY29tbWVyY2UuY29tghhzb3Vy
Y2UuYW5kcm9pZC5nb29nbGUuY26CCnVyY2hpbi5jb22CCnd3dy5nb28uZ2yCCHlv
dXR1LmJlggt5b3V0dWJlLmNvbYIUeW91dHViZWVkdWNhdGlvbi5jb22CD3lvdXR1
YmVraWRzLmNvbYIFeXQuYmUwIQYDVR0gBBowGDAIBgZngQwBAgIwDAYKKwYBBAHW
eQIFAzAzBgNVHR8ELDAqMCigJqAkhiJodHRwOi8vY3JsLnBraS5nb29nL0dUUzFP
MWNvcmUuY3JsMIIBBAYKKwYBBAHWeQIEAgSB9QSB8gDwAHUAB7dcG+V9aP/xsMYd
IxXHuuZXfFeUt2ruvGE6GmnTohwAAAF0tp+GwAAABAMARjBEAiBis68209UqRM3U
pdK8YoCfL8BrZY6+i6ORfGmo7neXTQIgSrcPvX7ZqP3uvT5yoJYFjbpZBwY9cwAV
W4n9855SnlcAdwDnEvKwN34aYvuOyQxhhPHqezfLVh0RJlvz4PNL8kFUbgAAAXS2
n4TVAAAEAwBIMEYCIQCRyG5B5Www1ro7CxWNLULQ96BNxtNTCko0bNCD5MejPQIh
AMNe5UO1cbG7u6oaO7/yRUt2O1OSewKoMddtPB1OUBh+MA0GCSqGSIb3DQEBCwUA
A4IBAQAN61JzpCZJVRZrpVJIRy6Hn65b0ZDBXTh3x6OpD3X2Y0Q6FRqaQuPUA7xg
DUvVnUUpMGsM2ylzUrtvJhSOCb32FU3g9FwVzTif/PRA5qniYRhysR2aa+NxHg5c
rua60gExT/oSHeGKpJUXTCTPypF4wJ1YvKOd7pRfNqlGR4Gfb6BVy/YCA3CW/bk0
yQ0k99iL/ancn2qGBn4++Z2XWGZHgo5FTvCtFl6ZrK01T+UeqhLp8kQOvyN58WiM
S+c/7a4M2GyzJe+niWodeKFY91N0SpBViX8cl0YmIm6CNmJdRt5AA+C/FmLgxh7F
wBPEtuosuW+JHwshTHwwylI7tT1x
-----END CERTIFICATE-----
 1 s:C = US, O = Google Trust Services, CN = GTS CA 1O1
   i:OU = GlobalSign Root CA - R2, O = GlobalSign, CN = GlobalSign
-----BEGIN CERTIFICATE-----
MIIESjCCAzKgAwIBAgINAeO0mqGNiqmBJWlQuDANBgkqhkiG9w0BAQsFADBMMSAw
HgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMjETMBEGA1UEChMKR2xvYmFs
U2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xNzA2MTUwMDAwNDJaFw0yMTEy
MTUwMDAwNDJaMEIxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVHb29nbGUgVHJ1c3Qg
U2VydmljZXMxEzARBgNVBAMTCkdUUyBDQSAxTzEwggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQDQGM9F1IvN05zkQO9+tN1pIRvJzzyOTHW5DzEZhD2ePCnv
UA0Qk28FgICfKqC9EksC4T2fWBYk/jCfC3R3VZMdS/dN4ZKCEPZRrAzDsiKUDzRr
mBBJ5wudgzndIMYcLe/RGGFl5yODIKgjEv/SJH/UL+dEaltN11BmsK+eQmMF++Ac
xGNhr59qM/9il71I2dN8FGfcddwuaej4bXhp0LcQBbjxMcI7JP0aM3T4I+DsaxmK
FsbjzaTNC9uzpFlgOIg7rR25xoynUxv8vNmkq7zdPGHXkxWY7oG9j+JkRyBABk7X
rJfoucBZEqFJJSPk7XA0LKW0Y3z5oz2D0c1tJKwHAgMBAAGjggEzMIIBLzAOBgNV
HQ8BAf8EBAMCAYYwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMBIGA1Ud
EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFJjR+G4Q68+b7GCfGJAboOt9Cf0rMB8G
A1UdIwQYMBaAFJviB1dnHB7AagbeWbSaLd/cGYYuMDUGCCsGAQUFBwEBBCkwJzAl
BggrBgEFBQcwAYYZaHR0cDovL29jc3AucGtpLmdvb2cvZ3NyMjAyBgNVHR8EKzAp
MCegJaAjhiFodHRwOi8vY3JsLnBraS5nb29nL2dzcjIvZ3NyMi5jcmwwPwYDVR0g
BDgwNjA0BgZngQwBAgIwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly9wa2kuZ29vZy9y
ZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEAGoA+Nnn78y6pRjd9XlQWNa7H
TgiZ/r3RNGkmUmYHPQq6Scti9PEajvwRT2iWTHQr02fesqOqBY2ETUwgZQ+lltoN
FvhsO9tvBCOIazpswWC9aJ9xju4tWDQH8NVU6YZZ/XteDSGU9YzJqPjY8q3MDxrz
mqepBCf5o8mw/wJ4a2G6xzUr6Fb6T8McDO22PLRL6u3M4Tzs3A2M1j6bykJYi8wW
IRdAvKLWZu/axBVbzYmqmwkm5zLSDW5nIAJbELCQCZwMH56t2Dvqofxs6BBcCFIZ
USpxu6x6td0V7SvJCCosirSmIatj/9dSSVDQibet8q/7UK4v4ZUN80atnZz1yg==
-----END CERTIFICATE-----
---
Server certificate
subject=C = US, ST = California, L = Mountain View, O = Google LLC, CN = *.google.com

issuer=C = US, O = Google Trust Services, CN = GTS CA 1O1

---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: ECDSA
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3832 bytes and written 390 bytes
Verification: OK
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 256 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
|}

let extended_validation_badssl =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:businessCategory = Private Organization, jurisdictionC = US, jurisdictionST = California, serialNumber = C2543436, C = US, ST = California, L = Mountain View, O = Mozilla Foundation, CN = extended-validation.badssl.com
   i:C = US, O = DigiCert Inc, OU = www.digicert.com, CN = DigiCert SHA2 Extended Validation Server CA
-----BEGIN CERTIFICATE-----
MIIHZDCCBkygAwIBAgIQDtsxL6s4mGkViYnesbc/1zANBgkqhkiG9w0BAQsFADB1
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMTQwMgYDVQQDEytEaWdpQ2VydCBTSEEyIEV4dGVuZGVk
IFZhbGlkYXRpb24gU2VydmVyIENBMB4XDTIwMDYyMzAwMDAwMFoXDTIyMDgxMDEy
MDAwMFowgeQxHTAbBgNVBA8MFFByaXZhdGUgT3JnYW5pemF0aW9uMRMwEQYLKwYB
BAGCNzwCAQMTAlVTMRswGQYLKwYBBAGCNzwCAQITCkNhbGlmb3JuaWExETAPBgNV
BAUTCEMyNTQzNDM2MQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEW
MBQGA1UEBxMNTW91bnRhaW4gVmlldzEbMBkGA1UEChMSTW96aWxsYSBGb3VuZGF0
aW9uMScwJQYDVQQDEx5leHRlbmRlZC12YWxpZGF0aW9uLmJhZHNzbC5jb20wggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDCBOz4jO4EwrPYUNVwWMyTGOtc
qGhJsCK1+ZWesSssdj5swEtgTEzqsrTAD4C2sPlyyYYC+VxBXRMrf3HES7zplC5Q
N6ZnHGGM9kFCxUbTFocnn3TrCp0RUiYhc2yETHlV5NFr6AY9SBVSrbMo26r/bv9g
lUp3aznxJNExtt1NwMT8U7ltQq21fP6u9RXSM0jnInHHwhR6bCjqN0rf6my1crR+
WqIW3GmxV0TbChKr3sMPR3RcQSLhmvkbk+atIgYpLrG6SRwMJ56j+4v3QHIArJII
2YxXhFOBBcvm/mtUmEAnhccQu3Nw72kYQQdFVXz5ZD89LMOpfOuTGkyG0cqFAgMB
AAGjggN+MIIDejAfBgNVHSMEGDAWgBQ901Cl1qCt7vNKYApl0yHU+PjWDzAdBgNV
HQ4EFgQUne7Be4ELOkdpcRh9ETeTvKUbP/swKQYDVR0RBCIwIIIeZXh0ZW5kZWQt
dmFsaWRhdGlvbi5iYWRzc2wuY29tMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAU
BggrBgEFBQcDAQYIKwYBBQUHAwIwdQYDVR0fBG4wbDA0oDKgMIYuaHR0cDovL2Ny
bDMuZGlnaWNlcnQuY29tL3NoYTItZXYtc2VydmVyLWcyLmNybDA0oDKgMIYuaHR0
cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItZXYtc2VydmVyLWcyLmNybDBLBgNV
HSAERDBCMDcGCWCGSAGG/WwCATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5k
aWdpY2VydC5jb20vQ1BTMAcGBWeBDAEBMIGIBggrBgEFBQcBAQR8MHowJAYIKwYB
BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBSBggrBgEFBQcwAoZGaHR0
cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkV4dGVuZGVkVmFs
aWRhdGlvblNlcnZlckNBLmNydDAMBgNVHRMBAf8EAjAAMIIBfwYKKwYBBAHWeQIE
AgSCAW8EggFrAWkAdgApeb7wnjk5IfBWc59jpXflvld9nGAK+PlNXSZcJV3HhAAA
AXLhwe8uAAAEAwBHMEUCIQC5/b5wmGbMOkgH/GupRPFXZ29CaGG8JQMFkjzgBz8n
owIgZQwjhH6rH8lbUX9y3+DLPyUJMA6JXy+18kKQ90JzanIAdwAiRUUHWVUkVpY/
oS/x922G4CMmY63AS39dxoNcbuIPAgAAAXLhwe84AAAEAwBIMEYCIQCI7jirWHoe
G5VW0FDM7MkB2pkUyi2RzM9JDFZ5HXfGJwIhAMWSFJKM57x+bFVfOJkqz3V0vDI/
nywkI96DpHE7tIDdAHYAQcjKsd8iRkoQxqE6CUKHXk4xixsD6+tLx2jwkGKWBvYA
AAFy4cHu+gAABAMARzBFAiASe/ZlNY2nqmcLX6hnjXu7exSER/BmhAVKHexAeGwU
dgIhAJunm2S4Hyz/ofuz4Cs98PknztPlRY3gSxO+ay8lr7XkMA0GCSqGSIb3DQEB
CwUAA4IBAQB0ZpWayltbvblCxkb/KI/UptbKSPex2C8HosV0cXZLdzkAa9UA9Vdg
IYNfkqVUpZH6Z3b7jtyZIUE7Thtcmglmm/OcPeLYOmO6L27T3igni2+b5mlj7L00
PjWsRforHnD7B+q8KnIpdLs4pJc/0hHK2yn11utAOgn+jnBXs3xoRxKYC+nXWM3C
Syhq4B+z/4clh3Mq+Jgse9h50uRf9bmn+n/TxCcfeiDdgY5Z2KNy+nPrP78Jhpl9
f8N6Kv+K8Mm398q8iHyM14V6o0VdrQUTr8ZmEa/KmRAL+eMRzbEZg+YlIyn9qQAy
A5GhqEwE29Z5Knslx7CvNEO9xV3CByfS
-----END CERTIFICATE-----
 1 s:C = US, O = DigiCert Inc, OU = www.digicert.com, CN = DigiCert SHA2 Extended Validation Server CA
   i:C = US, O = DigiCert Inc, OU = www.digicert.com, CN = DigiCert High Assurance EV Root CA
-----BEGIN CERTIFICATE-----
MIIEtjCCA56gAwIBAgIQDHmpRLCMEZUgkmFf4msdgzANBgkqhkiG9w0BAQsFADBs
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j
ZSBFViBSb290IENBMB4XDTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowdTEL
MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
LmRpZ2ljZXJ0LmNvbTE0MDIGA1UEAxMrRGlnaUNlcnQgU0hBMiBFeHRlbmRlZCBW
YWxpZGF0aW9uIFNlcnZlciBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBANdTpARR+JmmFkhLZyeqk0nQOe0MsLAAh/FnKIaFjI5j2ryxQDji0/XspQUY
uD0+xZkXMuwYjPrxDKZkIYXLBxA0sFKIKx9om9KxjxKws9LniB8f7zh3VFNfgHk/
LhqqqB5LKw2rt2O5Nbd9FLxZS99RStKh4gzikIKHaq7q12TWmFXo/a8aUGxUvBHy
/Urynbt/DvTVvo4WiRJV2MBxNO723C3sxIclho3YIeSwTQyJ3DkmF93215SF2AQh
cJ1vb/9cuhnhRctWVyh+HA1BV6q3uCe7seT6Ku8hI3UarS2bhjWMnHe1c63YlC3k
8wyd7sFOYn4XwHGeLN7x+RAoGTMCAwEAAaOCAUkwggFFMBIGA1UdEwEB/wQIMAYB
Af8CAQAwDgYDVR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEF
BQcDAjA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
Z2ljZXJ0LmNvbTBLBgNVHR8ERDBCMECgPqA8hjpodHRwOi8vY3JsNC5kaWdpY2Vy
dC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNlRVZSb290Q0EuY3JsMD0GA1UdIAQ2
MDQwMgYEVR0gADAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5j
b20vQ1BTMB0GA1UdDgQWBBQ901Cl1qCt7vNKYApl0yHU+PjWDzAfBgNVHSMEGDAW
gBSxPsNpA/i/RwHUmCYaCALvY2QrwzANBgkqhkiG9w0BAQsFAAOCAQEAnbbQkIbh
hgLtxaDwNBx0wY12zIYKqPBKikLWP8ipTa18CK3mtlC4ohpNiAexKSHc59rGPCHg
4xFJcKx6HQGkyhE6V6t9VypAdP3THYUYUN9XR3WhfVUgLkc3UHKMf4Ib0mKPLQNa
2sPIoc4sUqIAY+tzunHISScjl2SFnjgOrWNoPLpSgVh5oywM395t6zHyuqB8bPEs
1OG9d4Q3A84ytciagRpKkk47RpqF/oOi+Z6Mo8wNXrM9zwR4jxQUezKcxwCmXMS1
oVWNWlZopCJwqjyBcdmdqEU79OX2olHdx3ti6G8MdOu42vi/hw15UJGQmxg7kVkn
8TUoE6smftX3eg==
-----END CERTIFICATE-----
---
Server certificate
subject=businessCategory = Private Organization, jurisdictionC = US, jurisdictionST = California, serialNumber = C2543436, C = US, ST = California, L = Mountain View, O = Mozilla Foundation, CN = extended-validation.badssl.com

issuer=C = US, O = DigiCert Inc, OU = www.digicert.com, CN = DigiCert SHA2 Extended Validation Server CA

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 3620 bytes and written 456 bytes
Verification: OK
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 23F7C5ED976C5282E0560451480503D57BDA046969A848546C71191842D7613E
    Session-ID-ctx: 
    Master-Key: BEF4C35CC73EB08048FCAFA254DECE26E7A8A6841EC829D1B7F20E011F757E234E188B8B8C4948BF6762658D46E7C5D3
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1602435414
    Timeout   : 7200 (sec)
    Verify return code: 0 (ok)
    Extended master secret: no
---
|}

let ok_tests =
  [
    ("google.com", google);
    ("extended-validation.badssl.com", extended_validation_badssl);
  ]

let self_signed_badssl =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com
   i:C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com
-----BEGIN CERTIFICATE-----
MIIDeTCCAmGgAwIBAgIJAPziuikCTox4MA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNp
c2NvMQ8wDQYDVQQKDAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTAeFw0x
OTEwMDkyMzQxNTJaFw0yMTEwMDgyMzQxNTJaMGIxCzAJBgNVBAYTAlVTMRMwEQYD
VQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQK
DAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2
PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMW
hyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3A
xPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqve
ww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SY
QCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaMyMDAwCQYDVR0T
BAIwADAjBgNVHREEHDAaggwqLmJhZHNzbC5jb22CCmJhZHNzbC5jb20wDQYJKoZI
hvcNAQELBQADggEBAGlwCdbPxflZfYOaukZGCaxYK6gpincX4Lla4Ui2WdeQxE95
w7fChXvP3YkE3UYUE7mupZ0eg4ZILr/A0e7JQDsgIu/SRTUE0domCKgPZ8v99k3A
vka4LpLK51jHJJK7EFgo3ca2nldd97GM0MU41xHFk8qaK1tWJkfrrfcGwDJ4GQPI
iLlm6i0yHq1Qg1RypAXJy5dTlRXlCLd8ufWhhiwW0W75Va5AEnJuqpQrKwl3KQVe
wGj67WWRgLfSr+4QG1mNvCZb2CkjZWmxkGPuoP40/y7Yu5OFqxP5tAjj4YixCYTW
EVA0pmzIzgBg+JIe3PdRy27T0asgQW/F4TY61Yk=
-----END CERTIFICATE-----
---
Server certificate
subject=C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com

issuer=C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 1404 bytes and written 448 bytes
Verification error: self signed certificate
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: F6A1E369801FDF644904D6E4C4E1E29E9448CD8E0FDE574B9F42B9B026FA25BF
    Session-ID-ctx: 
    Master-Key: 90E3C3917FFE81FD81E05C0E2398499C1AC58C81F8D6B35AD7A3F2450F8B89BFF62710A3AC9AFD1378FADD8AD8EB79E0
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1602434632
    Timeout   : 7200 (sec)
    Verify return code: 18 (self signed certificate)
    Extended master secret: no
---
|}

let expired_badssl =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:OU = Domain Control Validated, OU = PositiveSSL Wildcard, CN = *.badssl.com
   i:C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO RSA Domain Validation Secure Server CA
-----BEGIN CERTIFICATE-----
MIIFSzCCBDOgAwIBAgIQSueVSfqavj8QDxekeOFpCTANBgkqhkiG9w0BAQsFADCB
kDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxNjA0BgNV
BAMTLUNPTU9ETyBSU0EgRG9tYWluIFZhbGlkYXRpb24gU2VjdXJlIFNlcnZlciBD
QTAeFw0xNTA0MDkwMDAwMDBaFw0xNTA0MTIyMzU5NTlaMFkxITAfBgNVBAsTGERv
bWFpbiBDb250cm9sIFZhbGlkYXRlZDEdMBsGA1UECxMUUG9zaXRpdmVTU0wgV2ls
ZGNhcmQxFTATBgNVBAMUDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2PmzA
S2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMWhyef
dOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3AxPxT
uW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqveww9H
dFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SYQCeF
xxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaOCAdUwggHRMB8GA1Ud
IwQYMBaAFJCvajqUWgvYkOoSVnPfQ7Q6KNrnMB0GA1UdDgQWBBSd7sF7gQs6R2lx
GH0RN5O8pRs/+zAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0TAQH/BAIwADAdBgNVHSUE
FjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwTwYDVR0gBEgwRjA6BgsrBgEEAbIxAQIC
BzArMCkGCCsGAQUFBwIBFh1odHRwczovL3NlY3VyZS5jb21vZG8uY29tL0NQUzAI
BgZngQwBAgEwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5jb21vZG9jYS5j
b20vQ09NT0RPUlNBRG9tYWluVmFsaWRhdGlvblNlY3VyZVNlcnZlckNBLmNybDCB
hQYIKwYBBQUHAQEEeTB3ME8GCCsGAQUFBzAChkNodHRwOi8vY3J0LmNvbW9kb2Nh
LmNvbS9DT01PRE9SU0FEb21haW5WYWxpZGF0aW9uU2VjdXJlU2VydmVyQ0EuY3J0
MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wIwYDVR0RBBww
GoIMKi5iYWRzc2wuY29tggpiYWRzc2wuY29tMA0GCSqGSIb3DQEBCwUAA4IBAQBq
evHa/wMHcnjFZqFPRkMOXxQhjHUa6zbgH6QQFezaMyV8O7UKxwE4PSf9WNnM6i1p
OXy+l+8L1gtY54x/v7NMHfO3kICmNnwUW+wHLQI+G1tjWxWrAPofOxkt3+IjEBEH
fnJ/4r+3ABuYLyw/zoWaJ4wQIghBK4o+gk783SHGVnRwpDTysUCeK1iiWQ8dSO/r
ET7BSp68ZVVtxqPv1dSWzfGuJ/ekVxQ8lEEFeouhN0fX9X3c+s5vMaKwjOrMEpsi
8TRwz311SotoKQwe6Zaoz7ASH1wq7mcvf71z81oBIgxw+s1F73hczg36TuHvzmWf
RwxPuzZEaFZcVlmtqoq8
-----END CERTIFICATE-----
 1 s:C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO RSA Domain Validation Secure Server CA
   i:C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO RSA Certification Authority
-----BEGIN CERTIFICATE-----
MIIGCDCCA/CgAwIBAgIQKy5u6tl1NmwUim7bo3yMBzANBgkqhkiG9w0BAQwFADCB
hTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNV
BAMTIkNPTU9ETyBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTQwMjEy
MDAwMDAwWhcNMjkwMjExMjM1OTU5WjCBkDELMAkGA1UEBhMCR0IxGzAZBgNVBAgT
EkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMR
Q09NT0RPIENBIExpbWl0ZWQxNjA0BgNVBAMTLUNPTU9ETyBSU0EgRG9tYWluIFZh
bGlkYXRpb24gU2VjdXJlIFNlcnZlciBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEP
ADCCAQoCggEBAI7CAhnhoFmk6zg1jSz9AdDTScBkxwtiBUUWOqigwAwCfx3M28Sh
bXcDow+G+eMGnD4LgYqbSRutA776S9uMIO3Vzl5ljj4Nr0zCsLdFXlIvNN5IJGS0
Qa4Al/e+Z96e0HqnU4A7fK31llVvl0cKfIWLIpeNs4TgllfQcBhglo/uLQeTnaG6
ytHNe+nEKpooIZFNb5JPJaXyejXdJtxGpdCsWTWM/06RQ1A/WZMebFEh7lgUq/51
UHg+TLAchhP6a5i84DuUHoVS3AOTJBhuyydRReZw3iVDpA3hSqXttn7IzW3uLh0n
c13cRTCAquOyQQuvvUSH2rnlG51/ruWFgqUCAwEAAaOCAWUwggFhMB8GA1UdIwQY
MBaAFLuvfgI9+qbxPISOre44mOzZMjLUMB0GA1UdDgQWBBSQr2o6lFoL2JDqElZz
30O0Oija5zAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNV
HSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwGwYDVR0gBBQwEjAGBgRVHSAAMAgG
BmeBDAECATBMBgNVHR8ERTBDMEGgP6A9hjtodHRwOi8vY3JsLmNvbW9kb2NhLmNv
bS9DT01PRE9SU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDBxBggrBgEFBQcB
AQRlMGMwOwYIKwYBBQUHMAKGL2h0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9E
T1JTQUFkZFRydXN0Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21v
ZG9jYS5jb20wDQYJKoZIhvcNAQEMBQADggIBAE4rdk+SHGI2ibp3wScF9BzWRJ2p
mj6q1WZmAT7qSeaiNbz69t2Vjpk1mA42GHWx3d1Qcnyu3HeIzg/3kCDKo2cuH1Z/
e+FE6kKVxF0NAVBGFfKBiVlsit2M8RKhjTpCipj4SzR7JzsItG8kO3KdY3RYPBps
P0/HEZrIqPW1N+8QRcZs2eBelSaz662jue5/DJpmNXMyYE7l3YphLG5SEXdoltMY
dVEVABt0iN3hxzgEQyjpFv3ZBdRdRydg1vs4O2xyopT4Qhrf7W8GjEXCBgCq5Ojc
2bXhc3js9iPc0d1sjhqPpepUfJa3w/5Vjo1JXvxku88+vZbrac2/4EjxYoIQ5QxG
V/Iz2tDIY+3GH5QFlkoakdH368+PUq4NCNk+qKBR6cGHdNXJ93SrLlP7u3r7l+L4
HyaPs9Kg4DdbKDsx5Q5XLVq4rXmsXiBmGqW5prU5wfWYQ//u+aen/e7KJD2AFsQX
j4rBYKEMrltDR5FL1ZoXX/nUh8HCjLfn4g8wGTeGrODcQgPmlKidrv0PJFGUzpII
0fxQ8ANAe4hZ7Q7drNJ3gjTcBpUC2JD5Leo31Rpg0Gcg19hCC0Wvgmje3WYkN5Ap
lBlGGSW4gNfL1IYoakRwJiNiqZ+Gb7+6kHDSVneFeO/qJakXzlByjAA6quPbYzSf
+AZxAeKCINT+b72x
-----END CERTIFICATE-----
 2 s:C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO RSA Certification Authority
   i:C = SE, O = AddTrust AB, OU = AddTrust External TTP Network, CN = AddTrust External CA Root
-----BEGIN CERTIFICATE-----
MIIFdDCCBFygAwIBAgIQJ2buVutJ846r13Ci/ITeIjANBgkqhkiG9w0BAQwFADBv
MQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFk
ZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBF
eHRlcm5hbCBDQSBSb290MB4XDTAwMDUzMDEwNDgzOFoXDTIwMDUzMDEwNDgzOFow
gYUxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAO
BgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSswKQYD
VQQDEyJDT01PRE8gUlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIICIjANBgkq
hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAkehUktIKVrGsDSTdxc9EZ3SZKzejfSNw
AHG8U9/E+ioSj0t/EFa9n3Byt2F/yUsPF6c947AEYe7/EZfH9IY+Cvo+XPmT5jR6
2RRr55yzhaCCenavcZDX7P0N+pxs+t+wgvQUfvm+xKYvT3+Zf7X8Z0NyvQwA1onr
ayzT7Y+YHBSrfuXjbvzYqOSSJNpDa2K4Vf3qwbxstovzDo2a5JtsaZn4eEgwRdWt
4Q08RWD8MpZRJ7xnw8outmvqRsfHIKCxH2XeSAi6pE6p8oNGN4Tr6MyBSENnTnIq
m1y9TBsoilwie7SrmNnu4FGDwwlGTm0+mfqVF9p8M1dBPI1R7Qu2XK8sYxrfV8g/
vOldxJuvRZnio1oktLqpVj3Pb6r/SVi+8Kj/9Lit6Tf7urj0Czr56ENCHonYhMsT
8dm74YlguIwoVqwUHZwK53Hrzw7dPamWoUi9PPevtQ0iTMARgexWO/bTouJbt7IE
IlKVgJNp6I5MZfGRAy1wdALqi2cVKWlSArvX31BqVUa/oKMoYX9w0MOiqiwhqkfO
KJwGRXa/ghgntNWutMtQ5mv0TIZxMOmm3xaG4Nj/QN370EKIf6MzOi5cHkERgWPO
GHFrK+ymircxXDpqR+DDeVnWIBqv8mqYqnK8V0rSS527EPywTEHl7R09XiidnMy/
s1Hap0flhFMCAwEAAaOB9DCB8TAfBgNVHSMEGDAWgBStvZh6NLQm9/rEJlTvA73g
JMtUGjAdBgNVHQ4EFgQUu69+Aj36pvE8hI6t7jiY7NkyMtQwDgYDVR0PAQH/BAQD
AgGGMA8GA1UdEwEB/wQFMAMBAf8wEQYDVR0gBAowCDAGBgRVHSAAMEQGA1UdHwQ9
MDswOaA3oDWGM2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9BZGRUcnVzdEV4dGVy
bmFsQ0FSb290LmNybDA1BggrBgEFBQcBAQQpMCcwJQYIKwYBBQUHMAGGGWh0dHA6
Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQADggEBAGS/g/FfmoXQ
zbihKVcN6Fr30ek+8nYEbvFScLsePP9NDXRqzIGCJdPDoCpdTPW6i6FtxFQJdcfj
Jw5dhHk3QBN39bSsHNA7qxcS1u80GH4r6XnTq1dFDK8o+tDb5VCViLvfhVdpfZLY
Uspzgb8c8+a4bmYRBbMelC1/kZWSWfFMzqORcUx8Rww7Cxn2obFshj5cqsQugsv5
B5a6SE2Q8pTIqXOi6wZ7I53eovNNVZ96YUWYGGjHXkBrI/V5eu+MtWuLt29G9Hvx
PUsE2JOAWVrgQSQdso8VYFhH2+9uRv0V9dlfmrPb2LjkQLPNlzmuhbsdjrzch5vR
pu/xO28QOG8=
-----END CERTIFICATE-----
---
Server certificate
subject=OU = Domain Control Validated, OU = PositiveSSL Wildcard, CN = *.badssl.com

issuer=C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO RSA Domain Validation Secure Server CA

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 4824 bytes and written 444 bytes
Verification error: certificate has expired
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 0E3D5C358767788B8935538CE2B86C4E7D0B932FC3A91153B45A698FF43E6313
    Session-ID-ctx: 
    Master-Key: B2B26F72CE2275A7BBF8D2EF170088E7FC98E83619009725FA07E5A3CD8B2E2B7AB36AD7DE63B2B31F649B7771E553EE
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1602434992
    Timeout   : 7200 (sec)
    Verify return code: 10 (certificate has expired)
    Extended master secret: no
---
|}

let untrusted_root_badssl =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com
   i:C = US, ST = California, L = San Francisco, O = BadSSL, CN = BadSSL Untrusted Root Certificate Authority
-----BEGIN CERTIFICATE-----
MIIEmTCCAoGgAwIBAgIJAOywCwT04S08MA0GCSqGSIb3DQEBCwUAMIGBMQswCQYD
VQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTEWMBQGA1UEBwwNU2FuIEZyYW5j
aXNjbzEPMA0GA1UECgwGQmFkU1NMMTQwMgYDVQQDDCtCYWRTU0wgVW50cnVzdGVk
IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTE5MTAwOTIzMDg1MFoXDTIx
MTAwODIzMDg1MFowYjELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWEx
FjAUBgNVBAcMDVNhbiBGcmFuY2lzY28xDzANBgNVBAoMBkJhZFNTTDEVMBMGA1UE
AwwMKi5iYWRzc2wuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
wgTs+IzuBMKz2FDVcFjMkxjrXKhoSbAitfmVnrErLHY+bMBLYExM6rK0wA+AtrD5
csmGAvlcQV0TK39xxEu86ZQuUDemZxxhjPZBQsVG0xaHJ5906wqdEVImIXNshEx5
VeTRa+gGPUgVUq2zKNuq/27/YJVKd2s58STRMbbdTcDE/FO5bUKttXz+rvUV0jNI
5yJxx8IUemwo6jdK3+pstXK0flqiFtxpsVdE2woSq97DD0d0XEEi4Zr5G5PmrSIG
KS6xukkcDCeeo/uL90ByAKySCNmMV4RTgQXL5v5rVJhAJ4XHELtzcO9pGEEHRVV8
+WQ/PSzDqXzrkxpMhtHKhQIDAQABozIwMDAJBgNVHRMEAjAAMCMGA1UdEQQcMBqC
DCouYmFkc3NsLmNvbYIKYmFkc3NsLmNvbTANBgkqhkiG9w0BAQsFAAOCAgEAhU5h
jESEo1M5HCTHYlC1EkoxRG+bBLaYtiDsJl3HwlhtYx+r03UvWrwJ7QXhjda1G9fC
313JBLtrainBgjgJXPDHW5fmYaTmNExo7i3d+OunalwS97RQKsFtY/c+CJhYgv25
8/TOkKhg7uvV/31Uac0cIW9qH7lulE0cBymtbmWvR7sBRjD+P1hU58AULAGyMhBw
ijGBGTqHP2tRb6oMLF+iC0Ej2Eho2qloKdoYaNFivBYPMrWBk8YBGKdKOYv12Kpy
AmWhkR+x4UYPIGzPXUcFz2685E0bxoVJq0+TTXaiyjPeQ9fSgsXxeGx37g9lQ4iA
uZb1qs/MiaVz1dQ7bXGtTQbpSkLjJtRF8Toh0/oJPeM9GGoMPswqcGDTE/wqhD2j
tSl5//9kgviVVCKLNbARDJ0ikpnkhB/2K37pz9of+ltYCVHc58cCFfgmCwZfl1nJ
Zyd36FfAlATZAG2V+5JE/oir6ggPN/f1Zs21wSTejpunkDaNqWZutYalmpg1hsq8
76RNkfxtkONIubPUI90ymmJ7h6l8YPmuV+J/CE7LzDVAU51+uvFjtPNvEmJPRfug
rXmQ974mtlnvQfhb+Z3WmERgczbQCSN6C/j6+U86KrUqYcALf5rkX9cVJ1qMp0XS
6/5tfSQQuvJ7vzHVdo0OWQ7IOaSnVVV/cXQjkB4=
-----END CERTIFICATE-----
 1 s:C = US, ST = California, L = San Francisco, O = BadSSL, CN = BadSSL Untrusted Root Certificate Authority
   i:C = US, ST = California, L = San Francisco, O = BadSSL, CN = BadSSL Untrusted Root Certificate Authority
-----BEGIN CERTIFICATE-----
MIIGfjCCBGagAwIBAgIJAJeg/PrX5Sj9MA0GCSqGSIb3DQEBCwUAMIGBMQswCQYD
VQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTEWMBQGA1UEBwwNU2FuIEZyYW5j
aXNjbzEPMA0GA1UECgwGQmFkU1NMMTQwMgYDVQQDDCtCYWRTU0wgVW50cnVzdGVk
IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTE2MDcwNzA2MzEzNVoXDTM2
MDcwMjA2MzEzNVowgYExCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlh
MRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQKDAZCYWRTU0wxNDAyBgNV
BAMMK0JhZFNTTCBVbnRydXN0ZWQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkw
ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDKQtPMhEH073gis/HISWAi
bOEpCtOsatA3JmeVbaWal8O/5ZO5GAn9dFVsGn0CXAHR6eUKYDAFJLa/3AhjBvWa
tnQLoXaYlCvBjodjLEaFi8ckcJHrAYG9qZqioRQ16Yr8wUTkbgZf+er/Z55zi1yn
CnhWth7kekvrwVDGP1rApeLqbhYCSLeZf5W/zsjLlvJni9OrU7U3a9msvz8mcCOX
fJX9e3VbkD/uonIbK2SvmAGMaOj/1k0dASkZtMws0Bk7m1pTQL+qXDM/h3BQZJa5
DwTcATaa/Qnk6YHbj/MaS5nzCSmR0Xmvs/3CulQYiZJ3kypns1KdqlGuwkfiCCgD
yWJy7NE9qdj6xxLdqzne2DCyuPrjFPS0mmYimpykgbPnirEPBF1LW3GJc9yfhVXE
Cc8OY8lWzxazDNNbeSRDpAGbBeGSQXGjAbliFJxwLyGzZ+cG+G8lc+zSvWjQu4Xp
GJ+dOREhQhl+9U8oyPX34gfKo63muSgo539hGylqgQyzj+SX8OgK1FXXb2LS1gxt
VIR5Qc4MmiEG2LKwPwfU8Yi+t5TYjGh8gaFv6NnksoX4hU42gP5KvjYggDpR+NSN
CGQSWHfZASAYDpxjrOo+rk4xnO+sbuuMk7gORsrl+jgRT8F2VqoR9Z3CEdQxcCjR
5FsfTymZCk3GfIbWKkaeLQIDAQABo4H2MIHzMB0GA1UdDgQWBBRvx4NzSbWnY/91
3m1u/u37l6MsADCBtgYDVR0jBIGuMIGrgBRvx4NzSbWnY/913m1u/u37l6MsAKGB
h6SBhDCBgTELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFjAUBgNV
BAcMDVNhbiBGcmFuY2lzY28xDzANBgNVBAoMBkJhZFNTTDE0MDIGA1UEAwwrQmFk
U1NMIFVudHJ1c3RlZCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eYIJAJeg/PrX
5Sj9MAwGA1UdEwQFMAMBAf8wCwYDVR0PBAQDAgEGMA0GCSqGSIb3DQEBCwUAA4IC
AQBQU9U8+jTRT6H9AIFm6y50tXTg/ySxRNmeP1Ey9Zf4jUE6yr3Q8xBv9gTFLiY1
qW2qfkDSmXVdBkl/OU3+xb5QOG5hW7wVolWQyKREV5EvUZXZxoH7LVEMdkCsRJDK
wYEKnEErFls5WPXY3bOglBOQqAIiuLQ0f77a2HXULDdQTn5SueW/vrA4RJEKuWxU
iD9XPnVZ9tPtky2Du7wcL9qhgTddpS/NgAuLO4PXh2TQ0EMCll5reZ5AEr0NSLDF
c/koDv/EZqB7VYhcPzr1bhQgbv1dl9NZU0dWKIMkRE/T7vZ97I3aPZqIapC2ulrf
KrlqjXidwrGFg8xbiGYQHPx3tHPZxoM5WG2voI6G3s1/iD+B4V6lUEvivd3f6tq7
d1V/3q1sL5DNv7TvaKGsq8g5un0TAkqaewJQ5fXLigF/yYu5a24/GUD783MdAPFv
gWz8F81evOyRfpf9CAqIswMF+T6Dwv3aw5L9hSniMrblkg+ai0K22JfoBcGOzMtB
Ke/Ps2Za56dTRoY/a4r62hrcGxufXd0mTdPaJLw3sJeHYjLxVAYWQq4QKJQWDgTS
dAEWyN2WXaBFPx5c8KIW95Eu8ShWE00VVC3oA4emoZ2nrzBXLrUScifY6VaYYkkR
2O2tSqU8Ri3XRdgpNPDWp8ZL49KhYGYo3R/k98gnMHiY5g==
-----END CERTIFICATE-----
---
Server certificate
subject=C = US, ST = California, L = San Francisco, O = BadSSL, CN = *.badssl.com

issuer=C = US, ST = California, L = San Francisco, O = BadSSL, CN = BadSSL Untrusted Root Certificate Authority

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 3361 bytes and written 451 bytes
Verification error: self signed certificate in certificate chain
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 649A3C21016DC17582243CEA5FF0E4A66E44261F2193BE54C11FAB1EE0CCBB9B
    Session-ID-ctx: 
    Master-Key: 4D6B719C876D3025D6C7BD3EA00D0EDE1D026C4A94713AAE19C170ABFF800FC0EE5FB6C4478BB5C9375A51E69D29BC45
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1602435337
    Timeout   : 7200 (sec)
    Verify return code: 19 (self signed certificate in certificate chain)
    Extended master secret: no
---
|}

let wrong_host_badssl =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:C = US, ST = California, L = Walnut Creek, O = Lucas Garron Torres, CN = *.badssl.com
   i:C = US, O = DigiCert Inc, CN = DigiCert SHA2 Secure Server CA
-----BEGIN CERTIFICATE-----
MIIGqDCCBZCgAwIBAgIQCvBs2jemC2QTQvCh6x1Z/TANBgkqhkiG9w0BAQsFADBN
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5E
aWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMjAwMzIzMDAwMDAwWhcN
MjIwNTE3MTIwMDAwWjBuMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5p
YTEVMBMGA1UEBxMMV2FsbnV0IENyZWVrMRwwGgYDVQQKExNMdWNhcyBHYXJyb24g
VG9ycmVzMRUwEwYDVQQDDAwqLmJhZHNzbC5jb20wggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQDCBOz4jO4EwrPYUNVwWMyTGOtcqGhJsCK1+ZWesSssdj5s
wEtgTEzqsrTAD4C2sPlyyYYC+VxBXRMrf3HES7zplC5QN6ZnHGGM9kFCxUbTFocn
n3TrCp0RUiYhc2yETHlV5NFr6AY9SBVSrbMo26r/bv9glUp3aznxJNExtt1NwMT8
U7ltQq21fP6u9RXSM0jnInHHwhR6bCjqN0rf6my1crR+WqIW3GmxV0TbChKr3sMP
R3RcQSLhmvkbk+atIgYpLrG6SRwMJ56j+4v3QHIArJII2YxXhFOBBcvm/mtUmEAn
hccQu3Nw72kYQQdFVXz5ZD89LMOpfOuTGkyG0cqFAgMBAAGjggNhMIIDXTAfBgNV
HSMEGDAWgBQPgGEcgjFh1S8o541GOLQs4cbZ4jAdBgNVHQ4EFgQUne7Be4ELOkdp
cRh9ETeTvKUbP/swIwYDVR0RBBwwGoIMKi5iYWRzc2wuY29tggpiYWRzc2wuY29t
MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
awYDVR0fBGQwYjAvoC2gK4YpaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NzY2Et
c2hhMi1nNi5jcmwwL6AtoCuGKWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zc2Nh
LXNoYTItZzYuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAEBMCowKAYIKwYBBQUH
AgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQIDMHwGCCsG
AQUFBwEBBHAwbjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29t
MEYGCCsGAQUFBzAChjpodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNl
cnRTSEEyU2VjdXJlU2VydmVyQ0EuY3J0MAwGA1UdEwEB/wQCMAAwggF+BgorBgEE
AdZ5AgQCBIIBbgSCAWoBaAB2ALvZ37wfinG1k5Qjl6qSe0c4V5UKq1LoGpCWZDaO
HtGFAAABcQhGXioAAAQDAEcwRQIgDfWVBXEuUZC2YP4Si3AQDidHC4U9e5XTGyG7
SFNDlRkCIQCzikrA1nf7boAdhvaGu2Vkct3VaI+0y8p3gmonU5d9DwB2ACJFRQdZ
VSRWlj+hL/H3bYbgIyZjrcBLf13Gg1xu4g8CAAABcQhGXlsAAAQDAEcwRQIhAMWi
Vsi2vYdxRCRsu/DMmCyhY0iJPKHE2c6ejPycIbgqAiAs3kSSS0NiUFiHBw7QaQ/s
GO+/lNYvjExlzVUWJbgNLwB2AFGjsPX9AXmcVm24N3iPDKR6zBsny/eeiEKaDf7U
iwXlAAABcQhGXnoAAAQDAEcwRQIgKsntiBqt8Au8DAABFkxISELhP3U/wb5lb76p
vfenWL0CIQDr2kLhCWP/QUNxXqGmvr1GaG9EuokTOLEnGPhGv1cMkDANBgkqhkiG
9w0BAQsFAAOCAQEA0RGxlwy3Tl0lhrUAn2mIi8LcZ9nBUyfAcCXCtYyCdEbjIP64
xgX6pzTt0WJoxzlT+MiK6fc0hECZXqpkTNVTARYtGkJoljlTK2vAdHZ0SOpm9OT4
RLfjGnImY0hiFbZ/LtsvS2Zg7cVJecqnrZe/za/nbDdljnnrll7C8O5naQuKr4te
uice3e8a4TtviFwS/wdDnJ3RrE83b1IljILbU5SV0X1NajyYkUWS7AnOmrFUUByz
MwdGrM6kt0lfJy/gvGVsgIKZocHdedPeECqAtq7FAJYanOsjNN9RbBOGhbwq0/FP
CC01zojqS10nGowxzOiqyB4m6wytmzf0QwjpMw==
-----END CERTIFICATE-----
 1 s:C = US, O = DigiCert Inc, CN = DigiCert SHA2 Secure Server CA
   i:C = US, O = DigiCert Inc, OU = www.digicert.com, CN = DigiCert Global Root CA
-----BEGIN CERTIFICATE-----
MIIElDCCA3ygAwIBAgIQAf2j627KdciIQ4tyS8+8kTANBgkqhkiG9w0BAQsFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0xMzAzMDgxMjAwMDBaFw0yMzAzMDgxMjAwMDBaME0xCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxJzAlBgNVBAMTHkRpZ2lDZXJ0IFNIQTIg
U2VjdXJlIFNlcnZlciBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
ANyuWJBNwcQwFZA1W248ghX1LFy949v/cUP6ZCWA1O4Yok3wZtAKc24RmDYXZK83
nf36QYSvx6+M/hpzTc8zl5CilodTgyu5pnVILR1WN3vaMTIa16yrBvSqXUu3R0bd
KpPDkC55gIDvEwRqFDu1m5K+wgdlTvza/P96rtxcflUxDOg5B6TXvi/TC2rSsd9f
/ld0Uzs1gN2ujkSYs58O09rg1/RrKatEp0tYhG2SS4HD2nOLEpdIkARFdRrdNzGX
kujNVA075ME/OV4uuPNcfhCOhkEAjUVmR7ChZc6gqikJTvOX6+guqw9ypzAO+sf0
/RR3w6RbKFfCs/mC/bdFWJsCAwEAAaOCAVowggFWMBIGA1UdEwEB/wQIMAYBAf8C
AQAwDgYDVR0PAQH/BAQDAgGGMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYY
aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMHsGA1UdHwR0MHIwN6A1oDOGMWh0dHA6
Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RDQS5jcmwwN6A1
oDOGMWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RD
QS5jcmwwPQYDVR0gBDYwNDAyBgRVHSAAMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8v
d3d3LmRpZ2ljZXJ0LmNvbS9DUFMwHQYDVR0OBBYEFA+AYRyCMWHVLyjnjUY4tCzh
xtniMB8GA1UdIwQYMBaAFAPeUDVW0Uy7ZvCj4hsbw5eyPdFVMA0GCSqGSIb3DQEB
CwUAA4IBAQAjPt9L0jFCpbZ+QlwaRMxp0Wi0XUvgBCFsS+JtzLHgl4+mUwnNqipl
5TlPHoOlblyYoiQm5vuh7ZPHLgLGTUq/sELfeNqzqPlt/yGFUzZgTHbO7Djc1lGA
8MXW5dRNJ2Srm8c+cftIl7gzbckTB+6WohsYFfZcTEDts8Ls/3HB40f/1LkAtDdC
2iDJ6m6K7hQGrn2iWZiIqBtvLfTyyRRfJs8sjX7tN8Cp1Tm5gr8ZDOo0rwAhaPit
c+LJMto4JQtV05od8GiG7S5BNO98pVAdvzr508EIDObtHopYJeS4d60tbvVS3bR0
j6tJLp07kzQoH3jOlOrHvdPJbRzeXDLz
-----END CERTIFICATE-----
---
Server certificate
subject=C = US, ST = California, L = Walnut Creek, O = Lucas Garron Torres, CN = *.badssl.com

issuer=C = US, O = DigiCert Inc, CN = DigiCert SHA2 Secure Server CA

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 3398 bytes and written 447 bytes
Verification: OK
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 3E96EF49E031153871907BFA4362E9AAD79785ED70996B1750AC7FB2004AA85D
    Session-ID-ctx: 
    Master-Key: 67084AF570632BD11B554FF000D5F67A34923BF512D9AE20E57627C6C8FACF80FA6D74A9298BEE5C908F72666813F2CC
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1602435542
    Timeout   : 7200 (sec)
    Verify return code: 0 (ok)
    Extended master secret: no
---
|}

let incomplete_chain_badssl =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:C = US, ST = California, L = Walnut Creek, O = Lucas Garron Torres, CN = *.badssl.com
   i:C = US, O = DigiCert Inc, CN = DigiCert SHA2 Secure Server CA
-----BEGIN CERTIFICATE-----
MIIGqDCCBZCgAwIBAgIQCvBs2jemC2QTQvCh6x1Z/TANBgkqhkiG9w0BAQsFADBN
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5E
aWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMjAwMzIzMDAwMDAwWhcN
MjIwNTE3MTIwMDAwWjBuMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5p
YTEVMBMGA1UEBxMMV2FsbnV0IENyZWVrMRwwGgYDVQQKExNMdWNhcyBHYXJyb24g
VG9ycmVzMRUwEwYDVQQDDAwqLmJhZHNzbC5jb20wggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQDCBOz4jO4EwrPYUNVwWMyTGOtcqGhJsCK1+ZWesSssdj5s
wEtgTEzqsrTAD4C2sPlyyYYC+VxBXRMrf3HES7zplC5QN6ZnHGGM9kFCxUbTFocn
n3TrCp0RUiYhc2yETHlV5NFr6AY9SBVSrbMo26r/bv9glUp3aznxJNExtt1NwMT8
U7ltQq21fP6u9RXSM0jnInHHwhR6bCjqN0rf6my1crR+WqIW3GmxV0TbChKr3sMP
R3RcQSLhmvkbk+atIgYpLrG6SRwMJ56j+4v3QHIArJII2YxXhFOBBcvm/mtUmEAn
hccQu3Nw72kYQQdFVXz5ZD89LMOpfOuTGkyG0cqFAgMBAAGjggNhMIIDXTAfBgNV
HSMEGDAWgBQPgGEcgjFh1S8o541GOLQs4cbZ4jAdBgNVHQ4EFgQUne7Be4ELOkdp
cRh9ETeTvKUbP/swIwYDVR0RBBwwGoIMKi5iYWRzc2wuY29tggpiYWRzc2wuY29t
MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
awYDVR0fBGQwYjAvoC2gK4YpaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NzY2Et
c2hhMi1nNi5jcmwwL6AtoCuGKWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zc2Nh
LXNoYTItZzYuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAEBMCowKAYIKwYBBQUH
AgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQIDMHwGCCsG
AQUFBwEBBHAwbjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29t
MEYGCCsGAQUFBzAChjpodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNl
cnRTSEEyU2VjdXJlU2VydmVyQ0EuY3J0MAwGA1UdEwEB/wQCMAAwggF+BgorBgEE
AdZ5AgQCBIIBbgSCAWoBaAB2ALvZ37wfinG1k5Qjl6qSe0c4V5UKq1LoGpCWZDaO
HtGFAAABcQhGXioAAAQDAEcwRQIgDfWVBXEuUZC2YP4Si3AQDidHC4U9e5XTGyG7
SFNDlRkCIQCzikrA1nf7boAdhvaGu2Vkct3VaI+0y8p3gmonU5d9DwB2ACJFRQdZ
VSRWlj+hL/H3bYbgIyZjrcBLf13Gg1xu4g8CAAABcQhGXlsAAAQDAEcwRQIhAMWi
Vsi2vYdxRCRsu/DMmCyhY0iJPKHE2c6ejPycIbgqAiAs3kSSS0NiUFiHBw7QaQ/s
GO+/lNYvjExlzVUWJbgNLwB2AFGjsPX9AXmcVm24N3iPDKR6zBsny/eeiEKaDf7U
iwXlAAABcQhGXnoAAAQDAEcwRQIgKsntiBqt8Au8DAABFkxISELhP3U/wb5lb76p
vfenWL0CIQDr2kLhCWP/QUNxXqGmvr1GaG9EuokTOLEnGPhGv1cMkDANBgkqhkiG
9w0BAQsFAAOCAQEA0RGxlwy3Tl0lhrUAn2mIi8LcZ9nBUyfAcCXCtYyCdEbjIP64
xgX6pzTt0WJoxzlT+MiK6fc0hECZXqpkTNVTARYtGkJoljlTK2vAdHZ0SOpm9OT4
RLfjGnImY0hiFbZ/LtsvS2Zg7cVJecqnrZe/za/nbDdljnnrll7C8O5naQuKr4te
uice3e8a4TtviFwS/wdDnJ3RrE83b1IljILbU5SV0X1NajyYkUWS7AnOmrFUUByz
MwdGrM6kt0lfJy/gvGVsgIKZocHdedPeECqAtq7FAJYanOsjNN9RbBOGhbwq0/FP
CC01zojqS10nGowxzOiqyB4m6wytmzf0QwjpMw==
-----END CERTIFICATE-----
---
Server certificate
subject=C = US, ST = California, L = Walnut Creek, O = Lucas Garron Torres, CN = *.badssl.com

issuer=C = US, O = DigiCert Inc, CN = DigiCert SHA2 Secure Server CA

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 2219 bytes and written 453 bytes
Verification error: unable to verify the first certificate
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 3A7DBDAC0199C67176A6191BC6ACC812FF469163BD550FCC0AC4CD7190C4980D
    Session-ID-ctx: 
    Master-Key: A45673CF402FD94CD1B0F4FF96DE8C2651B1DCDC230570AC62ACDAA7BF5D9235D1B66F9FBE4FFBE2746CF61935D5DB9D
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1602435786
    Timeout   : 7200 (sec)
    Verify return code: 21 (unable to verify the first certificate)
    Extended master secret: no
---
|}

let sha1_intermediate_badssl =
  {|
CONNECTED(00000003)
---
Certificate chain
 0 s:OU = Domain Control Validated, OU = COMODO SSL Wildcard, CN = *.badssl.com
   i:C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO SSL CA
-----BEGIN CERTIFICATE-----
MIIE8TCCA9mgAwIBAgIRAL4AQmnXWHlXEDwE56pO2LIwDQYJKoZIhvcNAQELBQAw
cDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxFjAUBgNV
BAMTDUNPTU9ETyBTU0wgQ0EwHhcNMTcwNDEzMDAwMDAwWhcNMjAwNTMwMjM1OTU5
WjBYMSEwHwYDVQQLExhEb21haW4gQ29udHJvbCBWYWxpZGF0ZWQxHDAaBgNVBAsT
E0NPTU9ETyBTU0wgV2lsZGNhcmQxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yo
aEmwIrX5lZ6xKyx2PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3
pmccYYz2QULFRtMWhyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CV
SndrOfEk0TG23U3AxPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5a
ohbcabFXRNsKEqveww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZ
jFeEU4EFy+b+a1SYQCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEA
AaOCAZwwggGYMB8GA1UdIwQYMBaAFBtrvR+KSRiUVDdVtCAX7Te5dxh9MB0GA1Ud
DgQWBBSd7sF7gQs6R2lxGH0RN5O8pRs/+zAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0T
AQH/BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwTwYDVR0gBEgw
RjA6BgsrBgEEAbIxAQICBzArMCkGCCsGAQUFBwIBFh1odHRwczovL3NlY3VyZS5j
b21vZG8uY29tL0NQUzAIBgZngQwBAgEwOAYDVR0fBDEwLzAtoCugKYYnaHR0cDov
L2NybC5jb21vZG9jYS5jb20vQ09NT0RPU1NMQ0EuY3JsMGkGCCsGAQUFBwEBBF0w
WzAzBggrBgEFBQcwAoYnaHR0cDovL2NydC5jb21vZG9jYS5jb20vQ09NT0RPU1NM
Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wIwYD
VR0RBBwwGoIMKi5iYWRzc2wuY29tggpiYWRzc2wuY29tMA0GCSqGSIb3DQEBCwUA
A4IBAQCjAoXzYKLon9rpcYVKD1Y3zvIZyojAiUgibAi/v3trIBDA92bOCxBNgCyw
yU3yFR8eSriE1lROeZghScU/qMKqJQhNv8jSRKiCaVjX/6XGJeGjJ4vDZgkoFOAt
3BUpzUSqCNZPuHim6YSIWRgcoCgvqzvh9wVh/eRTMGt2naTfy2ieUkYSKleGbE91
DeCKiiAJlimR0MJ5xOznTvCMxvs0ZppG41F+ain6rmsKQaVZfw4IxJW+9KmtNO4g
EJO5rT+lOyz3t3Ij2yblHAwtcdxxwyA9BdvnIxfDcXVtNcqPNfBZRkhct/APO/yS
Ix4MYaiI3P48eZeMnLgiw/MOh2Vi
-----END CERTIFICATE-----
 1 s:C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO SSL CA
   i:C = SE, O = AddTrust AB, OU = AddTrust External TTP Network, CN = AddTrust External CA Root
-----BEGIN CERTIFICATE-----
MIIE4jCCA8qgAwIBAgIQbrrwj3mD+p3hsm+W/G6YvzANBgkqhkiG9w0BAQUFADBv
MQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFk
ZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBF
eHRlcm5hbCBDQSBSb290MB4XDTExMDgyMzAwMDAwMFoXDTIwMDUzMDEwNDgzOFow
cDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxFjAUBgNV
BAMTDUNPTU9ETyBTU0wgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQDUKy4c0qP4f1UUQN73RN2EVfeFe1VmaaflWetlg/TzdrFmw09OmJMJt0Cz0Reg
EgmogOEpY5cCjDGdCgLgWVu77TC1735drwhOjYvCOVYWmHOUeArJpk8ot6g0N9sl
IbE8mfbgEj5z6mQyn0IGPBnYCgR6TFdJK9J3etAAvF76ju7MwuQTbiVf3DykiKPc
Sce8xw/dGcCxcu147ziDCkUXG8l9ne3fqywso3WuW4IdiIONzghlDGYmVwWhDN/m
B4QLhKPIq9WVR7/c3P4d/AKTRAHK5rW3axYwAV3piQmVnvheKVzdx1WM8o4gTkB6
5PVFA7SYK8SAflOHb8LSV7DpAgMBAAGjggF3MIIBczAfBgNVHSMEGDAWgBStvZh6
NLQm9/rEJlTvA73gJMtUGjAdBgNVHQ4EFgQUG2u9H4pJGJRUN1W0IBftN7l3GH0w
DgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEQYDVR0gBAowCDAG
BgRVHSAAMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwudXNlcnRydXN0LmNv
bS9BZGRUcnVzdEV4dGVybmFsQ0FSb290LmNybDCBswYIKwYBBQUHAQEEgaYwgaMw
PwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9BZGRUcnVzdEV4
dGVybmFsQ0FSb290LnA3YzA5BggrBgEFBQcwAoYtaHR0cDovL2NydC51c2VydHJ1
c3QuY29tL0FkZFRydXN0VVROU0dDQ0EuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8v
b2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBBQUAA4IBAQBDJTkjBwSsmV1Z
Zz3mL2F9WlZ7/AaNs0ud+tUFTA1mtb08x6Iqa7XP5rqDPmCQNgzVwu2KldmSQiMc
A3Y+wkjxdXKds4zPs1g0VkkdoS4rPbLoWhBG3mS1Ta5LbvwBtyEQ1ZW36yy+FAbM
QS7kbOJGkP/GKH5z/uUXuoLDEAWBZsKLKDigRD7p5M4zsHz44VOduLTL2sku2ZNw
jnwL43M+mZmP6+ERRDXYYIFiRdTeRVuQLkkbG9ukD4BiIXNp8ePebdhIfFYSJiIR
RwHGXhnCtJWX7mEAVfEEOPyE5ni0DUO+QzPdaNMiWwD7FILoS2J5MM/TlZ+zuYQB
1N3PIxL4
-----END CERTIFICATE-----
---
Server certificate
subject=OU = Domain Control Validated, OU = COMODO SSL Wildcard, CN = *.badssl.com

issuer=C = GB, ST = Greater Manchester, L = Salford, O = COMODO CA Limited, CN = COMODO SSL CA

---
No client certificate CA names sent
Peer signing digest: SHA512
Peer signature type: RSA
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 3037 bytes and written 454 bytes
Verification error: certificate has expired
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 1AA79F6F986D20959EFE3F4E293F2F5F05E1C33C779BB086A95C33B7B2A13716
    Session-ID-ctx: 
    Master-Key: 0F738EDA295FEA1972787E50BDFE693B8E0504BA41AC9EE75A6630CAEBD150693CCE7D2209F6D89482B1319C5975EA97
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1602436102
    Timeout   : 7200 (sec)
    Verify return code: 10 (certificate has expired)
    Extended master secret: no
---
|}

let err_tests =
  [
    ( "self-signed.badssl.com",
      (fun _ _ -> `InvalidChain),
      self_signed_badssl,
      None );
    ( "expired.badssl.com",
      (fun _ c -> `LeafCertificateExpired (List.hd c, Some now)),
      expired_badssl,
      None );
    ( "untrusted-root.badssl.com",
      (fun _ _ -> `InvalidChain),
      untrusted_root_badssl,
      None );
    ( "wrong.host.badssl.com",
      (fun h c -> `LeafInvalidName (List.hd c, Some h)),
      wrong_host_badssl,
      None );
    ( "incomplete-chain.badssl.com",
      (fun _ _ -> `InvalidChain),
      incomplete_chain_badssl,
      None );
    ( "sha1-intermediate.badssl.com",
      (fun _ _ -> `InvalidChain),
      sha1_intermediate_badssl,
      Some auth_2020_05_30 );
    ( "wrong.host.google.com",
      (fun h c -> `LeafInvalidName (List.hd c, Some h)),
      google,
      None );
  ]

let tests =
  List.map
    (fun (name, data) ->
      let host = Domain_name.(of_string_exn name |> host_exn)
      and chain =
        Result.get_ok
          (X509.Certificate.decode_pem_multiple (Cstruct.of_string data))
      in
      ( name,
        `Quick,
        test_one default_auth (Ok (Some (chain, List.hd chain))) host chain ))
    ok_tests
  @ List.map
      (fun (name, result, data, auth) ->
        let host = Domain_name.(of_string_exn name |> host_exn)
        and chain =
          Result.get_ok
            (X509.Certificate.decode_pem_multiple (Cstruct.of_string data))
        and auth = match auth with None -> default_auth | Some a -> a in
        (name, `Quick, test_one auth (Error (result host chain)) host chain))
      err_tests

let () =
  Alcotest.run "verification tests" [ ("X509 certificate validation", tests) ]
