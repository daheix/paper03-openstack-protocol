# P03 reproducible-package driver (protocol rule 12).
# Build context is the paper03_protocol repo root:
#   docker build -f repro/Dockerfile -t p03-repro:locked .
SHELL := /bin/bash
IMAGE ?= p03-repro:locked

.PHONY: build run verify help
build:            ## build the locked image
	docker build -f repro/Dockerfile -t $(IMAGE) .

run:              ## single locked reference solve (g2-6s2p-rd / A0)
	docker run --rm -v $$PWD/repro/verify_out:/p03/data/verify $(IMAGE) \
		python3 scripts/verify_repro.py

verify:           ## rerun + compare against expected_results (<=1% = PASS)
	docker run --rm $(IMAGE) make verify

help:
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | \
		awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'
