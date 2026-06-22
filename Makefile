LLAMAFILE_VERSION ?= 0.10.3

# Default model target
MODEL ?= granite-3.3-8b

CONFIG = models/$(MODEL).yaml
OUTPUT = $(shell grep '^output:' $(CONFIG) 2>/dev/null | sed 's/output:[[:space:]]*//' | tr -d '"')

.PHONY: all tools deps download package test clean help

all: tools download package

help:
	@echo "henry — llamafile factory"
	@echo ""
	@echo "Targets:"
	@echo "  make deps              Check all required tools are installed"
	@echo "  make tools             Download llamafile + zipalign binaries"
	@echo "  make download          Download GGUF for MODEL (default: $(MODEL))"
	@echo "  make package           Bundle GGUF into a llamafile"
	@echo "  make test              Smoke-test the built llamafile"
	@echo "  make all               Run tools + download + package"
	@echo "  make clean             Remove build outputs (keeps tools/ and models-cache/)"
	@echo ""
	@echo "Variables:"
	@echo "  MODEL=$(MODEL)   (any filename in models/ without .yaml)"
	@echo "  LLAMAFILE_VERSION=$(LLAMAFILE_VERSION)"
	@echo ""
	@echo "Examples:"
	@echo "  make all MODEL=granite-3.3-8b"

deps:
	@bash scripts/check-deps.sh

tools: deps
	@LLAMAFILE_VERSION=$(LLAMAFILE_VERSION) bash scripts/download-tools.sh

download: deps
	@bash scripts/download-model.sh $(CONFIG)

package:
	@bash scripts/package.sh $(CONFIG)

test:
	@bash scripts/test-llamafile.sh llamafiles/$(OUTPUT)

clean:
	@rm -f llamafiles/*.llamafile
	@echo "Cleaned llamafiles/"
