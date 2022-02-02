NAME := gomoku

.PHONY: switch
switch:
	opam update
	[[ $(shell opam switch show) == $(shell pwd) ]] || \
		opam switch create -y . 4.13.1 --deps-only --with-test --with-doc
	opam install merlin ocaml-lsp-server ocamlformat ocamlformat-rpc utop -y

.PHONY: dev
dev:
	opam update
	opam install merlin ocaml-lsp-server ocamlformat ocamlformat-rpc utop -y
	opam install --deps-only --with-test --with-doc -y .

.PHONY: build
build:
	dune build @install

.PHONY: watch
watch:
	sh ./watch.sh

.PHONY: run
run:
	dune exec $(NAME)

TEST ?= test

.PHONY: test
test:
	find . -name '*.coverage' | xargs rm -f
	dune build --no-print-directory \
	  --instrument-with bisect_ppx --force @$(TEST)/runtest
	bisect-ppx-report html
	bisect-ppx-report summary

.PHONY: test-watch
test-watch:
	dune build --no-print-directory -w --root . @$(TEST)/runtest

.PHONY: coverage-serve
coverage-serve:
	cd _coverage && dune exec -- simple-http-server -p 8082

.PHONY: promote
promote:
	dune promote --root .
	make --no-print-directory test

.PHONY: docs
docs:
	dune build @doc

WATCH:= \
	lib/**.mli

.PHONY: docs-watch
docs-watch:
	fswatch -o $(WATCH) | xargs -L 1 -I FOO make docs --no-print-directory

.PHONY: docs-open
docs-open:
	open _build/default/_doc/_html/index.html

.PHONY: clean
clean: 
	dune clean
	dune clean --root .
	rm -rf _coverage

.PHONY: utop
utop:
	dune utop

.PHONY: fmt
fmt:
	dune build @fmt --auto-promote
