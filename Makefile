LLAMAFILE_VERSION ?= 0.10.3

# Default model target
MODEL ?= granite-3.3-8b

CONFIG = models/$(MODEL).yaml
OUTPUT = $(shell grep '^output:' $(CONFIG) 2>/dev/null | sed 's/output:[[:space:]]*//' | tr -d '"')

# Use local Python venv if it exists
export PATH := .venv/bin:$(PATH)

.PHONY: all tools deps python-deps download convert quantize package test clean help

all: tools python-deps download package

help:
	@echo "henry — llamafile factory"
	@echo ""
	@echo "Targets:"
	@echo "  make deps              Check all required system tools are installed"
	@echo "  make python-deps       Check/install Python dependencies (PyTorch, etc.)"
	@echo "  make tools             Download llamafile + zipalign binaries"
	@echo "  make download          Download or build GGUF for MODEL (default: $(MODEL))"
	@echo "  make convert           Convert HF model to FP16 GGUF with custom template"
	@echo "  make quantize          Quantize FP16 GGUF to target method"
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
	@echo "  make all MODEL=granite-3.3-8b      # Pre-built GGUF (no PyTorch needed)"
	@echo "  make all MODEL=apertus-4b           # Source conversion (requires PyTorch)"

deps:
	@bash scripts/check-deps.sh

python-deps:
	@bash scripts/check-python-deps.sh

tools: deps
	@LLAMAFILE_VERSION=$(LLAMAFILE_VERSION) bash scripts/download-tools.sh

download: deps
	@bash scripts/download-model.sh $(CONFIG)

convert: deps python-deps
	@bash scripts/convert-model.sh $(CONFIG)

quantize: deps python-deps
	@bash scripts/quantize-model.sh $(CONFIG)

package:
	@bash scripts/package.sh $(CONFIG)

test:
	@bash scripts/test-llamafile.sh llamafiles/$(OUTPUT)

clean:
	@rm -f llamafiles/*.llamafile
	@echo "Cleaned llamafiles/"
