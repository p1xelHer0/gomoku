(lang dune 2.9.2)

(license MIT)

(generate_opam_files true)

(authors "Pontus Nagy")

(maintainers "p_nagy@icloud")

(source
 (github p1xelHer0/gomoku))

(documentation "https://github.com/p1xelHer0/gomoku")

(package
 (name gomoku)
 (synopsis "")
 (description "")
 (depends
   (ocaml (>= 4.13.1))
   (dune (and :build (>= 2.9.2)))

   (dream (>= "1.0.0~alpha2"))
   (fmt (>= 0.9.0))
   (logs (>= 0.7.0))
   (ppx_yojson_conv (>= 0.14.0))
   (rresult (>= 0.7.0))

   (alcotest (and :with-test (>= 1.5.0)))
   (bisect_ppx (and :with-test (>= 2.7.0)))

   (odoc :with-doc)))
