(lang dune 2.9.2)
(generate_opam_files true)

(name gomoku)

(authors "Pontus Nagy")
(maintainers "p_nagy@icloud")

(license MIT)
(documentation "https://github.com/p1xelHer0/gomoku")
(source
 (github p1xelHer0/gomoku))

(package
 (name gomoku)
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
