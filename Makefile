NAME := gomoku

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

.PHONY: switch
switch:
	opam switch create ./

.PHONY: deps
deps:
	opam install ./ --deps-only --with-test
	dune build

.PHONY: deps-editor
deps-editor:
	opam install ocaml-lsp-server merlin ocamlformat ocamlformat-rpc utop
