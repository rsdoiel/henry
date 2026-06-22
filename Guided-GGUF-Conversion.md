# Henry GGUF Conversion Guide

**Building Llamafiles from HuggingFace Models with Custom Features**

This guide explains how Henry converts HuggingFace models to GGUF format and packages them into Llamafiles, with support for custom chat templates, tool calling, embedding, and tagged content.

## Overview

Henry supports **two workflows** for creating GGUF files:

| Workflow | Description | Models | Customization |
|----------|-------------|--------|---------------|
| **Pre-built GGUF** | Downloads pre-converted GGUF from HuggingFace | Granite (default) | Limited to pre-built features |
| **Source Conversion** | Converts model sources to GGUF with custom templates | Apertus, others | Full control over features |

Both workflows produce quantized GGUF files that are then packaged into Llamafiles.

---

## Quick Start

### For Models with Pre-built GGUF (Granite)
```bash
make all MODEL=granite-3.3-8b
```

### For Models Built from Source (Apertus)
```bash
make all MODEL=apertus-4b
```

---

## Workflow 1: Pre-built GGUF (Granite Example)

This is the simplest workflow for models that already have GGUF versions available on HuggingFace.

### Configuration File: `models/granite-3.3-8b.yaml`

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
- `hf_repo`: Points to a HuggingFace repository containing **pre-built GGUF files**
- `gguf_file`: The specific GGUF file to download
- `convert`: **Missing or `false`** → triggers pre-built download workflow

### Process Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. DOWNLOAD (scripts/download-model.sh)                        │
│     ├── Parses config: hf_repo, gguf_file                      │
│     ├── Downloads: ibm-granite/granite-3.3-8b-instruct-GGUF     │
│     │   └── granite-3.3-8b-instruct-Q4_K_M.gguf                │
│     └── Saves to: models-cache/granite-3.3-8b/                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  2. PACKAGE (scripts/package.sh)                               │
│     ├── Copies: tools/llamafile → llamafiles/output.llamafile │
│     ├── Appends: GGUF file using zipalign                        │
│     └── Result: Standalone executable Llamafile              │
└─────────────────────────────────────────────────────────────┘
```

### Commands

```bash
# Check dependencies
make deps

# Download llamafile tools (llamafile binary, zipalign)
make tools

# Download pre-built GGUF
make download MODEL=granite-3.3-8b

# Package into Llamafile
make package MODEL=granite-3.3-8b

# Full build (all steps)
make all MODEL=granite-3.3-8b

# Clean up
make clean
```

### Files Created
```
models-cache/granite-3.3-8b/
  └── granite-3.3-8b-instruct-Q4_K_M.gguf    (~4.9 GB)

llamafiles/
  └── granite-3.3-8b-Q4_K_M.llamafile        (~5.0 GB executable)
```

---

## Workflow 2: Source Conversion (Apertus Example)

This workflow converts model **sources** (safetensors) to GGUF with custom chat templates, enabling features like tool calling and embedding support.

### Configuration File: `models/apertus-4b.yaml`

```yaml
name: apertus-4b
display_name: "Swiss-AI Apertus 4B Instruct"
hf_repo: swiss-ai/Apertus-v1.1-4B-Instruct
source_type: safetensors

# Build from source
convert: true              # ← KEY: Enables source conversion
quantization: Q4_K_M      # Target quantization method
context_length: 32768     # Extended context
chat_template: templates/apertus-4b-toolcall.jinja  # Custom template

# Output files
gguf_file: apertus-4b-instruct-Q4_K_M.gguf
output: apertus-4b-Q4_K_M.llamafile

# Features to bake into GGUF
features:
  - tool_calling
  - embedding
  - tagged

# Metadata
kind: instruct
ram_gb: 2
```

**Key Fields:**
- `hf_repo`: Points to the **source model** (not GGUF)
- `convert: true`: **Required** to trigger source conversion workflow
- `chat_template`: Path to custom Jinja template for tool calling support
- `context_length`: Extended to 32K for Apertus

### Custom Jinja Template: `templates/apertus-4b-toolcall.jinja`

```jinja
{%- set ns = namespace(prev_role=None) -%}
{{- bos_token -}}
{%- for message in messages -%}
    {%- set role = message['role'] -%}
    
    {%- if role == 'system' -%}
        {{- '<|im_start|>system\n' -}}
        {{- message['content'] | trim -}}
        {{- '\n<|im_end|>\n' -}}
    {%- elif role == 'user' -%}
        {{- '<|im_start|>user\n' -}}
        {{- message['content'] | trim -}}
        {{- '\n<|im_end|>\n' -}}
    {%- elif role == 'assistant' -%}
        {{- '<|im_start|>assistant\n' -}}
        
        {%- if message.get('tool_calls') -%}
            {%- for tool_call in message['tool_calls'] -%}
{{- '<tool_call>\n' -}}
{{- '{\n' -}}
{{- '  "id": "' + tool_call.get('id', 'call_' + loop.index|string) + '",\n' -}}
{{- '  "name": "' + tool_call['function']['name'] + '",\n' -}}
{{- '  "arguments": ' + tool_call['function']['arguments']|string + '\n' -}}
{{- '}\n' -}}
{{- '</tool_call>\n' -}}
            {%- endfor -%}
        {%- endif -%}
        
        {%- if message.get('content') -%}
{{- message['content'] | trim -}}
        {%- endif -%}
        
        {{- '\n<|im_end|>\n' -}}
    {%- endif -%}
{%- endfor -%}
{%- if add_generation_prompt -%}
    {{- '<|im_start|>assistant\n' -}}
{%- endif -%}
```

**Template Features:**
- `<|im_start|>` and `<|im_end|>` tokens for message boundaries
- `<tool_call>` tags for tool invocation
- JSON-formatted tool call metadata (id, name, arguments)
- Supports system, user, and assistant roles
- Handles both text content and tool calls in assistant messages

### Process Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. DOWNLOAD (scripts/download-model.sh)                        │
│     ├── Detects: convert: true                                   │
│     └── Calls: convert-model.sh + quantize-model.sh             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  2. CONVERT (scripts/convert-model.sh)                         │
│     ├── Downloads source: swiss-ai/Apertus-v1.1-4B-Instruct    │
│     │   └── Saves to: models-cache/apertus-4b/source/          │
│     ├── Auto-clones: llama.cpp (if needed)                       │
│     │   └── To: henry/llama.cpp/                                 │
│     ├── Converts to FP16 GGUF                                   │
│     │   └── Uses: templates/apertus-4b-toolcall.jinja          │
│     │   └── Output: models-cache/apertus-4b/apertus-4b...gguf │
│     └── Marks: .converted file                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  3. QUANTIZE (scripts/quantize-model.sh)                       │
│     ├── Auto-builds: llama-quantize (if needed)                 │
│     ├── Input: FP16 GGUF                                          │
│     ├── Method: Q4_K_M (from config)                             │
│     └── Output: Quantized GGUF (~2.5-3 GB for 4B)             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  4. PACKAGE (scripts/package.sh)                               │
│     └── Same as pre-built workflow                              │
└─────────────────────────────────────────────────────────────┘
```

### Commands

```bash
# Check dependencies
make deps

# Download llamafile tools
make tools

# Full build (download source + convert + quantize + package)
make all MODEL=apertus-4b

# Or step-by-step:
make convert MODEL=apertus-4b    # Source → FP16 GGUF
make quantize MODEL=apertus-4b   # FP16 → Q4_K_M
make package MODEL=apertus-4b    # GGUF → Llamafile

# Clean up
make clean
```

### Files Created
```
models-cache/apertus-4b/
  ├── source/                    # Downloaded model sources
  │   ├── config.json
  │   ├── tokenizer.json
  │   ├── tokenizer.model
  │   └── model-*.safetensors
  ├── apertus-4b-instruct-Q4_K_M.gguf.fp16.gguf  (~8 GB)
  └── apertus-4b-instruct-Q4_K_M.gguf            (~2.5-3 GB)

llamafiles/
  └── apertus-4b-Q4_K_M.llamafile               (~3 GB executable)
```

---

## Configuration Reference

### YAML Fields for All Models

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | ✅ | - | Internal model name (used for directories) |
| `display_name` | string | ❌ | - | Human-readable model name |
| `hf_repo` | string | ✅ | - | HuggingFace repository |
| `output` | string | ✅ | - | Output Llamafile name |
| `kind` | string | ❌ | - | Model type (instruct, base, etc.) |
| `quantization` | string | ❌ | Q4_K_M | Target quantization method |
| `context_length` | int | ❌ | 8192 | Model context length |
| `ram_gb` | int | ❌ | - | Approximate RAM needed |
| `notes` | string | ❌ | - | Additional notes |

### YAML Fields for Pre-built GGUF (Granite)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `gguf_file` | string | ✅ | - | Pre-built GGUF filename to download |
| `features` | list | ❌ | - | Features already in pre-built GGUF |

**Example:**
```yaml
hf_repo: ibm-granite/granite-3.3-8b-instruct-GGUF
gguf_file: granite-3.3-8b-instruct-Q4_K_M.gguf
```

### YAML Fields for Source Conversion (Apertus)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `source_type` | string | ❌ | safetensors | Source format |
| `convert` | boolean | ✅ | - | Must be `true` to enable conversion |
| `gguf_file` | string | ✅ | - | Output GGUF filename (will be generated) |
| `chat_template` | string | ✅ | - | Path to Jinja template |
| `features` | list | ❌ | - | Features to bake into GGUF |

**Example:**
```yaml
hf_repo: swiss-ai/Apertus-v1.1-4B-Instruct
source_type: safetensors
convert: true
quantization: Q4_K_M
context_length: 32768
chat_template: templates/apertus-4b-toolcall.jinja
gguf_file: apertus-4b-instruct-Q4_K_M.gguf
```

---

## Custom Chat Templates

### Creating a New Template

Create a new `.jinja` file in the `templates/` directory.

**Template Requirements:**
1. Must use `{{- bos_token -}}` at the start
2. Must iterate over `messages` array
3. Must handle: `system`, `user`, `assistant` roles
4. For tool calling: Handle `tool_calls` array in assistant messages

### Template Variables Available

| Variable | Type | Description |
|----------|------|-------------|
| `messages` | array | Array of message objects |
| `message['role']` | string | One of: system, user, assistant |
| `message['content']` | string | Message text content |
| `message['tool_calls']` | array | Tool calls (assistant only) |
| `tool_call['function']['name']` | string | Tool/function name |
| `tool_call['function']['arguments']` | string/object | Tool arguments |
| `add_generation_prompt` | boolean | Whether to add generation prompt |
| `bos_token` | string | Beginning-of-sequence token |

### Example: Minimal Template

```jinja
{{- bos_token -}}
{%- for message in messages -%}
{%- if message['role'] == 'user' -%}
{{- '<|im_start|>user\n' + message['content'] + '\n<|im_end|>\n' -}}
{%- elif message['role'] == 'assistant' -%}
{{- '<|im_start|>assistant\n' + message['content'] + '\n<|im_end|>\n' -}}
{%- endif -%}
{%- endfor -%}
{%- if add_generation_prompt -%}
{{- '<|im_start|>assistant\n' -}}
{%- endif -%}
```

---

## Quantization Methods

Henry supports all quantization methods available in `llama.cpp`:

| Method | Size (4B) | Quality | Speed | Use Case |
|--------|-----------|---------|-------|----------|
| `Q4_0` | ~2.3 GB | Medium | Fast | General use |
| **`Q4_K_M`** | **~2.5 GB** | **High** | **Fast** | **Recommended** |
| `Q5_0` | ~2.8 GB | Higher | Medium | Better quality |
| `Q5_K_M` | ~3.0 GB | Very High | Medium | High quality |
| `Q6_K` | ~3.5 GB | Very High | Medium | High quality |
| `Q8_0` | ~4.0 GB | Highest | Slow | Best quality |

**Recommendation:** Use `Q4_K_M` for the best balance of size, quality, and speed.

---

## Dependencies

### System Dependencies

| Tool | Purpose | Check |
|------|---------|-------|
| `make` | Build orchestration | `make --version` |
| `git` | Version control, cloning | `git --version` |
| `curl` | Download files | `curl --version` |
| `bash` | Script execution | `bash --version` |
| `python3` | Conversion scripts | `python3 --version` |

### Python Dependencies (for source conversion)

```bash
# Install required Python packages
pip install transformers>=4.56.0 safetensors sentencepiece accelerate
pip install huggingface_hub
```

Or using `uv`:
```bash
uv pip install transformers>=4.56.0 safetensors sentencepiece accelerate
uv pip install huggingface_hub
```

### llama.cpp (auto-installed)

Henry will automatically:
1. Clone `llama.cpp` from GitHub if not present
2. Build the required tools (`convert-hf-to-gguf.py`, `llama-quantize`)

To manually install:
```bash
cd henry
git clone https://github.com/ggml-org/llama.cpp.git --depth 1
cd llama.cpp
make -j $(nproc)
cd ..
```

---

## Troubleshooting

### Common Issues

#### 1. Python Not Found
```
ERROR: python3 is required for conversion
```
**Solution:** Install Python 3.8+
```bash
# macOS
brew install python

# Ubuntu/Debian
sudo apt install python3 python3-pip
```

#### 2. llama.cpp Build Failed
```
ERROR: Failed to build llama-quantize
```
**Solution:** Install build dependencies
```bash
# Ubuntu/Debian
sudo apt install build-essential cmake

# macOS (with Xcode CLI tools)
xcode-select --install
```

#### 3. Model Download Failed
```
ERROR: Failed to download swiss-ai/Apertus-v1.1-4B-Instruct
```
**Solution:**
- Check HuggingFace login: `hf whoami`
- Accept model terms if required: Visit the model page on HuggingFace
- Ensure `hf` CLI is installed: `uv tool install huggingface_hub[cli]`

#### 4. Out of Disk Space
```
No space left on device
```
**Solution:**
- 4B model source: ~8 GB
- FP16 GGUF: ~8 GB
- Quantized GGUF: ~2.5-3 GB
- **Total temporary space needed: ~20 GB**
- Clear cache: `rm -rf models-cache/`

#### 5. Template Not Found
```
ERROR: Template not found: templates/apertus-4b-toolcall.jinja
```
**Solution:**
- Verify template exists: `ls templates/`
- Check YAML `chat_template` field
- Ensure path is relative to Henry root

#### 6. Conversion Failed
```
ERROR: Conversion failed, output file not created
```
**Solution:**
- Check `convert-hf-to-gguf.py` logs
- Verify model source files are complete
- Try with a smaller model first (e.g., 0.5B Apertus)

---

## Adding a New Model

### For Pre-built GGUF Models (like Granite)

1. **Create config file:**
   ```bash
   cp models/granite-3.3-8b.yaml models/new-model.yaml
   ```

2. **Edit the config:**
   ```yaml
   name: new-model
display_name: "New Model"
hf_repo: org/new-model-GGUF
gguf_file: new-model-Q4_K_M.gguf
output: new-model-Q4_K_M.llamafile
   ```

3. **Build:**
   ```bash
   make all MODEL=new-model
   ```

### For Source Conversion Models (like Apertus)

1. **Create config file:**
   ```bash
   cp models/apertus-4b.yaml models/new-model.yaml
   ```

2. **Edit the config:**
   ```yaml
   name: new-model
display_name: "New Model"
hf_repo: org/new-model
source_type: safetensors
convert: true
quantization: Q4_K_M
context_length: 32768
chat_template: templates/new-model.jinja
gguf_file: new-model-Q4_K_M.gguf
output: new-model-Q4_K_M.llamafile
   ```

3. **Create custom template:**
   ```bash
   cp templates/apertus-4b-toolcall.jinja templates/new-model.jinja
   # Edit template for your model's tokenizer
   ```

4. **Build:**
   ```bash
   make all MODEL=new-model
   ```

---

## Model Comparison

| Model | Size | Source | Features | Notes |
|-------|------|--------|----------|-------|
| Granite 3.3 8B | 8B | Pre-built GGUF | Tool calling, Function calling | IBM model, ready to use |
| Apertus 4B | 4B | Source conversion | Tool calling, Embedding, Tagged | Swiss-AI, multilingual |
| Apertus 8B | 8B | Source conversion | Tool calling, Embedding, Tagged | Swiss-AI, multilingual |

### Granite vs Apertus

| Feature | Granite 3.3 8B | Apertus 4B |
|---------|----------------|------------|
| **Parameters** | 8B | 4B |
| **Context Length** | 8192 | 32768 |
| **Languages** | English-focused | 1811 languages |
| **Tool Calling** | ✅ Baked in | ✅ Custom template |
| **Embedding** | ✅ | ✅ |
| **Size (Q4_K_M)** | ~4.9 GB | ~2.5-3 GB |
| **RAM Usage** | ~6 GB | ~4-6 GB |
| **Compliance** | IBM | EU AI Act |
| **Source** | Pre-built | Convert from source |

---

## References

- [Henry Repository](https://github.com/rsdoiel/henry) (hypothetical)
- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [Apertus Models](https://huggingface.co/swiss-ai)
- [Granite Models](https://huggingface.co/ibm-granite)
- [GGUF Format](https://github.com/ggml-org/gguf)

---

## Appendix: Manual Commands

If you need to run steps manually (for debugging):

### For Apertus (Source Conversion)

```bash
# 1. Download source model
HF_REPO="swiss-ai/Apertus-v1.1-4B-Instruct"
MODEL_DIR="models-cache/apertus-4b/source"
mkdir -p "$MODEL_DIR"
hf download "$HF_REPO" --local-dir "$MODEL_DIR" --local-dir-use-symlinks False

# 2. Convert to FP16 GGUF
python3 llama.cpp/convert-hf-to-gguf.py \
    "$MODEL_DIR" \
    models-cache/apertus-4b/apertus-4b.fp16.gguf \
    --outtype f16 \
    --chat-template-file templates/apertus-4b-toolcall.jinja \
    --context-length 32768

# 3. Quantize to Q4_K_M
./llama.cpp/build/bin/llama-quantize \
    models-cache/apertus-4b/apertus-4b.fp16.gguf \
    models-cache/apertus-4b/apertus-4b-instruct-Q4_K_M.gguf \
    Q4_K_M

# 4. Package into Llamafile
cp tools/llamafile llamafiles/apertus-4b-Q4_K_M.llamafile
zipalign -j0 llamafiles/apertus-4b-Q4_K_M.llamafile \
    models-cache/apertus-4b/apertus-4b-instruct-Q4_K_M.gguf
chmod +x llamafiles/apertus-4b-Q4_K_M.llamafile
```

### For Granite (Pre-built GGUF)

```bash
# 1. Download pre-built GGUF
HF_REPO="ibm-granite/granite-3.3-8b-instruct-GGUF"
GGUF_FILE="granite-3.3-8b-instruct-Q4_K_M.gguf"
mkdir -p models-cache/granite-3.3-8b
hf download "$HF_REPO" "$GGUF_FILE" --local-dir models-cache/granite-3.3-8b

# 2. Package into Llamafile
cp tools/llamafile llamafiles/granite-3.3-8b-Q4_K_M.llamafile
zipalign -j0 llamafiles/granite-3.3-8b-Q4_K_M.llamafile \
    models-cache/granite-3.3-8b/$GGUF_FILE
chmod +x llamafiles/granite-3.3-8b-Q4_K_M.llamafile
```

---

*Last updated: June 2026*
