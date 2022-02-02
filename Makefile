NAME := gomoku

.PHONY: help
help:
	@echo "- make dev               setup opam swtich, install dependencies and editor tools"
	@echo "- make build             to build the project"
	@echo "- make run               to run the server"
	@echo "- make watch             to run the project in watch mode"
	@echo "- make test              to run the tests"
	@echo "- make test-watch        to run the tests in watch mode"
	@echo "- make coverage-serve    to serve the coverage on https://localhost:8002"
	@echo "- make docs              to build the docs"
	@echo "- make docs-watch        to build the docs in watch mode"
	@echo "- make docs-open         to open the docs"
	@echo "- make fmt               to format the code"
	@echo "- make utop              to run utop"
	@echo "- make clean             to clean the project"

.PHONY: dev
switch:
	opam update
	[[ $(shell opam switch show) == $(shell pwd) ]] || \
		opam switch create -y . 4.13.1 --deps-only --with-test --with-doc
	opam install merlin ocaml-lsp-server ocamlformat ocamlformat-rpc utop -y

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
