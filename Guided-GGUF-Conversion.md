# Henry GGUF Conversion Guide

**Building Llamafiles from HuggingFace Models with Custom Features**

*Version: 1.2 - Updated June 2026*

This guide explains how Henry converts HuggingFace models to GGUF format and packages them into Llamafiles, with full support for custom chat templates, tool calling, embedding, and tagged content.

## Overview

Henry is a **Factory for building Llamafiles** from open models on Hugging Face. It supports **three workflows**:

| Workflow | Description | Models | Customization | Status |
|----------|-------------|--------|---------------|--------|
| **Pre-built GGUF** | Downloads pre-converted GGUF from HuggingFace | Granite 3.3 8B | Limited to pre-built features | ✅ Default |
| **Source Conversion** | Converts model sources to GGUF with custom templates | Apertus 4B, Granite 3.3/4.1 | Full control over features | ✅ Available |

All workflows produce quantized GGUF files that are then packaged into **standalone Llamafile executables**.

---

## Quick Start

### Pre-built GGUF (Fastest)
```bash
# Original Granite 3.3 8B with baked-in tool support
make all MODEL=granite-3.3-8b
```

### Source Conversion (Custom Features)
```bash
# Granite 3.3 8B - Full control, 128K context
make all MODEL=granite-3.3-8b-source

# Granite 4.1 3B - Enhanced tool calling, 128K+ context
make all MODEL=granite-4.1-3b-source

# Apertus 4B - Custom template, multilingual
make all MODEL=apertus-4b
```

---

## Supported Models

### IBM Granite Models

| Model | Config File | Type | Size | Context | Features |
|-------|-------------|------|------|---------|----------|
| Granite 3.3 8B | `granite-3.3-8b.yaml` | Pre-built GGUF | 8B | 8K | Tool calling, function calling |
| **Granite 3.3 8B** | **`granite-3.3-8b-source.yaml`** | **Source conversion** | **8B** | **128K** | **Tool calling, embedding, tagged, function calling** |
| **Granite 4.1 3B** | **`granite-4.1-3b-source.yaml`** | **Source conversion** | **3B** | **128K+** | **Tool calling, embedding, tagged, function calling** |

> **Note:** There is currently no official IBM Granite 4B *text* model. The closest is Granite 4.1 3B (3 billion parameters) or Granite Vision 4.1 4B (vision-language model).

### Swiss-AI Apertus Models

| Model | Config File | Type | Size | Context | Features |
|-------|-------------|------|------|---------|----------|
| **Apertus 4B** | **`apertus-4b.yaml`** | **Source conversion** | **4B** | **32K** | **Tool calling, embedding, tagged** |

---

## Workflow 1: Pre-built GGUF (Granite 3.3 8B)

This is the **fastest workflow** for models that already have GGUF versions available on HuggingFace.

### Configuration File
`models/granite-3.3-8b.yaml`

```yaml
name: granite-3.3-8b
display_name: "IBM Granite 3.3 8B Instruct"
hf_repo: ibm-granite/granite-3.3-8b-instruct-GGUF
gguf_file: granite-3.3-8b-instruct-Q4_K_M.gguf
output: granite-3.3-8b-Q4_K_M.llamafile
kind: instruct
quantization: Q4_K_M
context_length: 8192
features:
  - tool_calling
  - function_calling
notes: >
  Granite 3.3 8B with Q4_K_M quantization (~4.9 GB file).
  Tool-call tags are baked into the GGUF chat template.
```

**Key Fields:**
- `hf_repo`: Points to pre-built GGUF repository
- `gguf_file`: Pre-built GGUF to download
- `convert`: Missing/false → uses pre-built workflow

### Process Flow
```
┌─────────────────────────────────────────────────────────────┐
│  1. DOWNLOAD (scripts/download-model.sh)                        │
│     ├── Parses: hf_repo, gguf_file                               │
│     ├── Downloads: ibm-granite/granite-3.3-8b-instruct-GGUF     │
│     │   └── granite-3.3-8b-instruct-Q4_K_M.gguf                │
│     └── Saves to: models-cache/granite-3.3-8b/                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  2. PACKAGE (scripts/package.sh)                               │
│     ├── Copies: tools/llamafile → llamafiles/output.llamafile │
│     ├── Appends: GGUF using zipalign                             │
│     └── Result: Standalone executable Llamafile                │
└─────────────────────────────────────────────────────────────┘
```

### Commands
```bash
make deps          # Check dependencies
make tools         # Download llamafile + zipalign
make download      # Download pre-built GGUF
make package       # Package into Llamafile
make all           # All steps combined
make clean         # Clean up
```

Example:
```bash
make all MODEL=granite-3.3-8b
```

---

## Workflow 2: Source Conversion (Granite 3.3 8B)

Converts **Granite 3.3 8B from source** with custom chat template for full control over features.

### Configuration File
`models/granite-3.3-8b-source.yaml`

```yaml
name: granite-3.3-8b-source
display_name: "IBM Granite 3.3 8B Instruct (Source)"
hf_repo: ibm-granite/granite-3.3-8b-instruct
source_type: safetensors
convert: true              # ← Enables source conversion
quantization: Q4_K_M
context_length: 122880    # Full 128K context
chat_template: templates/granite-toolcall.jinja
gguf_file: granite-3.3-8b-instruct-Q4_K_M.gguf
output: granite-3.3-8b-source-Q4_K_M.llamafile
features:
  - tool_calling
  - embedding
  - tagged
  - function_calling
kind: instruct
ram_gb: 6
```

### Custom Template
`templates/granite-toolcall.jinja`

- **Tool Calling**: `<tool_call>` tags with JSON metadata
- **Tagged Content**: `<think>` and `<response>` tags (Granite native)
- **Message Boundaries**: `<|im_start|>` and `<|im_end|>` tokens
- **Structured Output**: Machine-readable tool calls

### Process Flow
```
┌─────────────────────────────────────────────────────────────┐
│  1. DOWNLOAD (detects convert:true)                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  2. CONVERT (scripts/convert-model.sh)                         │
│     ├── Downloads: ibm-granite/granite-3.3-8b-instruct        │
│     ├── Auto-clones: llama.cpp if needed                        │
│     ├── Converts: Safetensors → FP16 GGUF                      │
│     │   └── Uses: templates/granite-toolcall.jinja           │
│     └── Output: models-cache/.../granite-3.3-8b.fp16.gguf      │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  3. QUANTIZE (scripts/quantize-model.sh)                       │
│     ├── Auto-builds: llama-quantize if needed                   │
│     ├── Quantizes: FP16 → Q4_K_M                                │
│     └── Output: models-cache/.../granite-3.3-8b-Q4_K_M.gguf   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  4. PACKAGE (scripts/package.sh)                               │
│     └── Packages GGUF into Llamafile                           │
└─────────────────────────────────────────────────────────────┘
```

### Commands
```bash
make all MODEL=granite-3.3-8b-source    # Full build
make convert MODEL=granite-3.3-8b-source  # Source → FP16
make quantize MODEL=granite-3.3-8b-source # FP16 → Q4_K_M
make package MODEL=granite-3.3-8b-source  # GGUF → Llamafile
```

---

## Workflow 3: Source Conversion (Granite 4.1 3B)

Converts **Granite 4.1 3B from source** with enhanced tool calling and extended context.

### Configuration File
`models/granite-4.1-3b-source.yaml`

```yaml
name: granite-4.1-3b-source
display_name: "IBM Granite 4.1 3B Instruct (Source)"
hf_repo: ibm-granite/granite-4.1-3b
source_type: safetensors
convert: true
quantization: Q4_K_M
context_length: 131072    # Full 128K+ context
chat_template: templates/granite-toolcall.jinja
gguf_file: granite-4.1-3b-instruct-Q4_K_M.gguf
output: granite-4.1-3b-source-Q4_K_M.llamafile
features:
  - tool_calling
  - embedding
  - tagged
  - function_calling
kind: instruct
ram_gb: 2
```

### Key Features
- **Granite 4.1 family**: Improved SFT+RL pipelines
- **Enhanced tool calling**: Better function integration
- **128K+ context**: 131072 token context length
- **Smaller footprint**: 3B parameters (~2 GB RAM)

### Commands
```bash
make all MODEL=granite-4.1-3b-source
```

---

## Workflow 4: Source Conversion (Apertus 4B)

Converts **Swiss-AI Apertus 4B from source** with custom template for tool calling.

### Configuration File
`models/apertus-4b.yaml`

```yaml
name: apertus-4b
display_name: "Swiss-AI Apertus 4B Instruct"
hf_repo: swiss-ai/Apertus-v1.1-4B-Instruct
source_type: safetensors
convert: true
quantization: Q4_K_M
context_length: 32768
chat_template: templates/apertus-4b-toolcall.jinja
gguf_file: apertus-4b-instruct-Q4_K_M.gguf
output: apertus-4b-Q4_K_M.llamafile
features:
  - tool_calling
  - embedding
  - tagged
kind: instruct
ram_gb: 2
```

### Custom Template
`templates/apertus-4b-toolcall.jinja`

- **Tool Calling**: `<tool_call>` tags with JSON
- **Tagged Content**: Custom format
- **Message Boundaries**: `<|im_start|>` and `<|im_end|>`
- **Multilingual**: Supports 1811 languages

### Commands
```bash
make all MODEL=apertus-4b
```

---

## Model Comparison

### Granite Family

| Model | Size | Workflow | Context | RAM | Features |
|-------|------|----------|---------|-----|----------|
| `granite-3.3-8b` | 8B | Pre-built | 8K | ~6 GB | Tool calling, function calling |
| `granite-3.3-8b-source` | 8B | Source | 128K | ~6 GB | **All features** |
| `granite-4.1-3b-source` | 3B | Source | 128K+ | ~2 GB | **All features, enhanced** |

### Apertus Family

| Model | Size | Workflow | Context | RAM | Languages | Compliance |
|-------|------|----------|---------|-----|-----------|------------|
| `apertus-4b` | 4B | Source | 32K | ~2 GB | 1811 | EU AI Act |

### Feature Matrix

| Feature | Granite 3.3 8B (Pre-built) | Granite 3.3 8B (Source) | Granite 4.1 3B (Source) | Apertus 4B (Source) |
|---------|----------------------------|--------------------------|-------------------------|---------------------|
| Tool Calling | ✅ Baked in | ✅ Custom template | ✅ Enhanced | ✅ Custom template |
| Embedding | ✅ | ✅ Explicit | ✅ Explicit | ✅ Explicit |
| Tagged Content | ✅ Native | ✅ Custom + Native | ✅ Custom + Native | ✅ Custom |
| Context Length | 8K | 128K | 128K+ | 32K |
| Customization | ❌ | ✅ Full | ✅ Full | ✅ Full |
| Multilingual | 12 | 12 | 12 | **1811** |

---

## Configuration Reference

### Common YAML Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | ✅ | - | Internal name (directory names) |
| `display_name` | string | ❌ | - | Human-readable name |
| `hf_repo` | string | ✅ | - | HuggingFace repository |
| `output` | string | ✅ | - | Output Llamafile name |
| `kind` | string | ❌ | - | Model type (instruct/base) |
| `quantization` | string | ❌ | Q4_K_M | Quantization method |
| `context_length` | int | ❌ | 8192 | Context length in tokens |

### Pre-built Specific Fields

| Field | Type | Description |
|-------|------|-------------|
| `gguf_file` | string | GGUF filename to download |
| `features` | list | Pre-built features |

### Source Conversion Specific Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source_type` | string | ❌ | Source format (safetensors) |
| `convert` | boolean | ✅ | Must be `true` |
| `chat_template` | string | ✅ | Jinja template path |

---

## Custom Chat Templates

### Available Templates

| Template | Models | Features |
|----------|--------|----------|
| `granite-toolcall.jinja` | Granite 3.3, 4.1 | `<tool_call>`, `<think>`, `<response>` |
| `apertus-4b-toolcall.jinja` | Apertus 4B | `<tool_call>` |

### Template Variables

| Variable | Type | Description |
|----------|------|-------------|
| `messages` | array | Message objects |
| `message['role']` | string | system/user/assistant |
| `message['content']` | string | Text content |
| `message['tool_calls']` | array | Tool calls |
| `tool_call['function']` | object | Tool definition |
| `bos_token` | string | BOS token |
| `add_generation_prompt` | boolean | Add generation prompt? |

### Creating Custom Templates

1. Create file in `templates/` directory
2. Start with `{{- bos_token -}}`
3. Iterate over `messages`
4. Handle each role (system/user/assistant)
5. For tool calls: Check `message.get('tool_calls')`

---

## Quantization Methods

| Method | Size (8B) | Size (3B) | Quality | Speed | Recommended |
|--------|-----------|-----------|---------|-------|-------------|
| `Q4_0` | ~4.5 GB | ~1.7 GB | Medium | Fast | ❌ |
| **`Q4_K_M`** | **~4.9 GB** | **~1.8 GB** | **High** | **Fast** | **✅** |
| `Q5_0` | ~5.5 GB | ~2.0 GB | Higher | Medium | ❌ |
| `Q5_K_M` | ~6.0 GB | ~2.2 GB | Very High | Medium | ❌ |
| `Q6_K` | ~7.0 GB | ~2.5 GB | Very High | Medium | ❌ |
| `Q8_0` | ~8.0 GB | ~3.0 GB | Highest | Slow | ❌ |

---

## Dependencies

### System

| Tool | Check | Install |
|------|-------|---------|
| `make` | `make --version` | Xcode (macOS), `sudo apt install make` (Linux) |
| `git` | `git --version` | `sudo apt install git` |
| `curl` | `curl --version` | `sudo apt install curl` |
| `python3` | `python3 --version` | `brew install python` / `sudo apt install python3` |
| `uv` | `uv --version` | `pip install --user uv` (required for package management) |

### Python Packages

**Automatic Installation**: Henry automatically creates a local Python virtual environment in the `.venv/` directory and installs all dependencies there when you run `make all` or `make python-deps`. This makes Henry **self-contained** - all Python packages are installed within the project directory.

Required packages:
- `torch` (PyTorch) - Installed from PyTorch CPU wheel repository
- `transformers>=4.56.0`
- `safetensors`
- `sentencepiece`
- `accelerate`
- `huggingface_hub`

The Makefile automatically uses the local venv's Python when running commands.

> **Note:** Henry requires `uv` for creating and managing the virtual environment. Install it first with `pip install --user uv` if you don't have it. The `.venv/` directory is added to `.gitignore` so it won't be committed to version control.

### llama.cpp

Auto-installed by Henry. Manual install:
```bash
cd henry
git clone https://github.com/ggml-org/llama.cpp.git --depth 1
cd llama.cpp && make -j $(nproc)
```

---

## Make Targets

| Target | Description |
|--------|-------------|
| `make deps` | Check dependencies |
| `make tools` | Download llamafile tools |
| `make download` | Download/build GGUF |
| `make convert` | Convert source to FP16 GGUF |
| `make quantize` | Quantize FP16 to target |
| `make package` | Package GGUF into Llamafile |
| `make test` | Smoke-test Llamafile |
| `make all` | Full build (tools + download + package) |
| `make clean` | Clean build outputs |
| `make help` | Show help |

### Examples

```bash
# Pre-built Granite (fastest)
make all MODEL=granite-3.3-8b

# Source Granite 8B (full control)
make all MODEL=granite-3.3-8b-source

# Source Granite 3B (enhanced)
make all MODEL=granite-4.1-3b-source

# Source Apertus 4B (multilingual)
make all MODEL=apertus-4b
```

---

## Troubleshooting

### Python Not Found
```
ERROR: python3 is required for conversion
```
**Fix:** Install Python 3.8+

### uv Not Found
```
ERROR: uv is required for package management
```
**Fix:** Install uv first: `pip install --user uv`

### Local venv Creation Failed
```
ERROR: Failed to create venv
```
**Fix:** Ensure you have `uv` installed and that your system Python is working. Henry creates a `.venv/` directory in the project root. Make sure you have write permissions in the Henry directory.

### Python Dependencies Missing
```
MISSING: torch
MISSING: transformers
```
**Fix:** Run `make python-deps` or `make all`. Henry will automatically create a local venv in `.venv/` and install all missing packages there. The Makefile automatically uses the venv's Python for all commands.

### llama.cpp Build Failed
```
ERROR: Failed to build llama-quantize
```
**Fix:** Install build tools: `sudo apt install build-essential cmake` (Linux) or `xcode-select --install` (macOS)

### Model Download Failed
```
ERROR: Failed to download...
```
**Fix:** Check `hf whoami`, accept model terms, install `hf` CLI: `uv tool install huggingface_hub[cli]`

### Out of Disk Space
**Fix:** Need ~20-25 GB for source conversion. Clear with `rm -rf models-cache/`

### Template Not Found
**Fix:** Verify `ls templates/`, check YAML `chat_template` path

---

## Directory Structure

```
henry/
├── .venv/                          # Local Python virtual environment (gitignored)
│   └── bin/python3                  # Venv Python with all dependencies
├── models/
│   ├── granite-3.3-8b.yaml           # Pre-built
│   ├── granite-3.3-8b-source.yaml    # Source conversion
│   ├── granite-4.1-3b-source.yaml    # Source conversion
│   └── apertus-4b.yaml                # Source conversion
├── templates/
│   ├── granite-toolcall.jinja        # For Granite
│   └── apertus-4b-toolcall.jinja      # For Apertus
├── scripts/
│   ├── check-python-deps.sh          # Check/install Python dependencies
│   ├── convert-model.sh              # Convert source to GGUF
│   ├── quantize-model.sh             # Quantize GGUF
│   └── download-model.sh             # Download/build models
├── models-cache/
│   └── <model>/
│       ├── source/                  # Source files
│       └── *.gguf                   # GGUF files
├── llamafiles/
│   └── *.llamafile                  # Output
├── Makefile                         # Build system
└── Guided-GGUF-Conversion.md        # This guide
```

---

## Adding New Models

### Pre-built GGUF
```bash
cp models/granite-3.3-8b.yaml models/new.yaml
# Edit: name, hf_repo, gguf_file, output
make all MODEL=new
```

### Source Conversion
```bash
cp models/granite-3.3-8b-source.yaml models/new.yaml
# Edit: name, hf_repo, chat_template, etc.
cp templates/granite-toolcall.jinja templates/new.jinja
# Edit template as needed
make all MODEL=new
```

---

## FAQ

**Q: Pre-built vs Source conversion?**
A: Pre-built is faster (downloads ready GGUF). Source gives full control (custom templates, extended context).

**Q: Which Granite to use?**
A: Use both! Keep `granite-3.3-8b.yaml` for quick deployment and `granite-3.3-8b-source.yaml` for full control.

**Q: Where is Granite 4B?**
A: IBM doesn't have a text-only 4B Granite. Use `granite-4.1-3b-source.yaml` (3B) or wait for official 4B release.

**Q: How to test tool calling?**
A: Start server: `./llamafiles/model.llamafile --server --port 8080` then send request with `tools` array.

---

## Appendix: Manual Commands

### Granite 3.3 8B Source

```bash
# 1. Download source
mkdir -p models-cache/granite-3.3-8b-source/source
hf download ibm-granite/granite-3.3-8b-instruct \
  --local-dir models-cache/granite-3.3-8b-source/source

# 2. Convert to FP16 GGUF
python3 llama.cpp/convert-hf-to-gguf.py \
  models-cache/granite-3.3-8b-source/source \
  models-cache/granite-3.3-8b-source/granite-3.3-8b.fp16.gguf \
  --outtype f16 \
  --chat-template-file templates/granite-toolcall.jinja \
  --context-length 122880

# 3. Quantize
./llama.cpp/build/bin/llama-quantize \
  models-cache/granite-3.3-8b-source/granite-3.3-8b.fp16.gguf \
  models-cache/granite-3.3-8b-source/granite-3.3-8b-Q4_K_M.gguf \
  Q4_K_M

# 4. Package
cp tools/llamafile llamafiles/granite-3.3-8b-source-Q4_K_M.llamafile
zipalign -j0 llamafiles/granite-3.3-8b-source-Q4_K_M.llamafile \
  models-cache/granite-3.3-8b-source/granite-3.3-8b-Q4_K_M.gguf
chmod +x llamafiles/granite-3.3-8b-source-Q4_K_M.llamafile
```

---

## References

- [IBM Granite Models](https://huggingface.co/ibm-granite)
- [Swiss-AI Apertus Models](https://huggingface.co/swiss-ai)
- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [GGUF Format](https://github.com/ggml-org/gguf)

---

*Last updated: June 22, 2026*
*Henry version: 0.0.2*
