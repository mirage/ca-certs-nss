(lang dune 2.7)
(name ca-certs-nss)

(generate_opam_files true)
(source (github mirage/ca-certs-nss))
(documentation "https://mirage.github.io/ca-certs-nss/doc")
(license ISC)
(maintainers "Hannes Mehnert <hannes@mehnert.org>")
(authors "Hannes Mehnert <hannes@mehnert.org>")

(package
 (name ca-certs-nss)
 (depends
  (mirage-clock (>= 3.0.0))
  (x509 (>= 1.0.0))
  (ocaml (>= 4.13.0))
  (digestif (>= 1.2.0))
  (logs :build)
  (fmt (and :build (>= 0.8.7)))
  (bos :build)
  (cmdliner (and :build (>= 1.1.0)))
  (alcotest :with-test))
 (conflicts (result (< 1.5)))
 (synopsis "X.509 trust anchors extracted from Mozilla's NSS")
 (description
   "\> Trust anchors extracted from Mozilla's NSS certdata.txt package,
   "\> to be used in MirageOS unikernels.
 )
 ; tags are not included before (lang dune 2.0)
 ; so an opam template is necessary until then
 (tags (org:mirage)))
