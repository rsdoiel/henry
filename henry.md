# Henry: Llamafile Factory Guide

## Overview

Henry is a factory for building **Llamafiles** (and GUFF files) from open models hosted on HuggingFace.co. It automates the process of downloading, converting, quantizing, and packaging models into self-contained, executable Llamafiles that can run anywhere without additional dependencies.

### What Henry Can Do

- **Download models** from Hugging Face Hub
- **Convert models** from Hugging Face format (safetensors/pytorch) to GGUF format
- **Apply custom chat templates** for proper model interaction
- **Quantize models** to reduce file size and memory requirements
- **Package GGUF files** into executable Llamafiles
- **Test** the generated Llamafiles

### Supported Outputs

- **Llamafiles**: Self-contained executable model files
- **GGUF files**: Standalone model weights in GGUF format

## Software Requirements

### System Tools

| Tool | Purpose | Download/Install |
|------|---------|------------------|
| `uv` | Python package manager | [https://docs.astral.sh/uv/](https://docs.astral.sh/uv/) |
| `git` | Version control | Package manager (apt, brew, etc.) |
| `make` | Build automation | Package manager (apt, brew, etc.) |
| `curl` | File downloads | Package manager (apt, brew, etc.) |
| `hf` | Hugging Face CLI | `uv tool install huggingface_hub[cli]` |

### Python Dependencies

| Package | Purpose | Notes |
|---------|---------|-------|
| `torch` | PyTorch deep learning framework | Install with `--extra-index-url https://download.pytorch.org/whl/cpu` |
| `transformers` | Hugging Face transformers | |
| `safetensors` | Safe tensor serialization | |
| `sentencepiece` | Tokenizer support | |
| `accelerate` | Training/Inference acceleration | |
| `huggingface_hub` | Hugging Face Hub access | |
| `tqdm` | Progress bars | |
| `gguf` | GGUF format support | |

### Optional Tools

| Tool | Purpose |
|------|---------|
| `cmake` | Build system for llama.cpp quantize tool |
| `g++`/clang | C++ compiler for building quantize tool |

## Quick Start: Generate Granite 4.1 8B Model

This step-by-step guide walks you through generating a Granite 4.1 8B Llamafile using Henry.

### Step 1: Clone Henry Repository

```bash
git clone https://github.com/rsdoiel/henry.git
cd henry
```

### Step 2: Install System Dependencies

#### macOS (Homebrew)

```bash
# Install system tools
brew install git make curl cmake

# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### macOS (MacPorts)

```bash
# Install system tools
sudo port install git make curl cmake

# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### Linux (Ubuntu/Debian)

```bash
# Install system tools
sudo apt update
sudo apt install -y git make curl cmake g++

# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### Windows (WSL2 recommended)

```powershell
# Install system tools via Chocolatey
choco install git make curl cmake

# Install uv
Invoke-WebRequest -Uri https://astral.sh/uv/install.ps1 -UseWebRequest | Invoke-Expression
```

### Step 3: Install Python Dependencies

Henry will automatically create a Python virtual environment and install required packages:

```bash
# This will create .venv/ and install all Python dependencies
make python-deps
```

**Manual installation (if needed):**

```bash
# Create virtual environment
uv venv .venv

# Activate it
source .venv/bin/activate  # Linux/macOS
# or .\.venv\Scripts\activate on Windows

# Install PyTorch (CPU version)
uv pip install torch --extra-index-url https://download.pytorch.org/whl/cpu

# Install other dependencies
uv pip install transformers safetensors sentencepiece accelerate huggingface_hub tqdm gguf

# Install hf CLI
uv tool install huggingface_hub[cli]
```

### Step 4: Download Tools

Download the llamafile binary and zipalign tool:

```bash
make tools
```

This downloads:
- `llamafile` - The Mozilla AI Llamafile launcher
- `zipalign` - Tool for bundling GGUF into the llamafile

Both are downloaded to the `tools/` directory.

### Step 5: Check Dependencies

Verify all dependencies are installed:

```bash
make deps
```

This checks for `uv`, `git`, `make`, `curl`, and `hf` CLI.

### Step 6: Generate Granite 4.1 8B Llamafile

Henry provides a pre-configured model definition for Granite 4.1 8B. The model configuration is in `models/granite-4.1-8b-source.yaml`.

#### Option A: Full Build from Source (Recommended)

This builds the GGUF from the original model weights with custom chat template:

```bash
# Build everything: tools, dependencies, download, convert, quantize, package
make all MODEL=granite-4.1-8b-source
```

This performs:
1. Downloads the Granite 4.1 8B model from `ibm-granite/granite-4.1-8b` on Hugging Face
2. Converts it to FP16 GGUF format
3. Applies the IBM Granite chat template (`llama.cpp/models/templates/ibm-granite-granite-4.1.jinja`)
4. Sets context length to 131,072 tokens
5. Quantizes to Q4_K_M quantization
6. Packages into a self-contained llamafile

#### Option B: Individual Steps

For more control, run each step individually:

```bash
# 1. Check dependencies
make deps

# 2. Install Python dependencies
make python-deps

# 3. Download tools
make tools

# 4. Download and convert model
make download MODEL=granite-4.1-8b-source

# 5. Quantize (already included in download for convert=true models)
make quantize MODEL=granite-4.1-8b-source

# 6. Package into llamafile
make package MODEL=granite-4.1-8b-source
```

### Step 7: Test the Llamafile

Once the build completes, test your new Llamafile:

```bash
make test MODEL=granite-4.1-8b-source
```

Or run it directly:

```bash
# List available llamafiles
ls -lh llamafiles/

# Run the Granite 4.1 8B model
./llamafiles/granite-4.1-8b-source-Q4_K_M.llamafile
```

The Llamafile is self-contained and can be copied to any system with the same architecture to run.

### Step 8: Clean Up (Optional)

To remove built llamafiles (keeps downloaded tools and cached models):

```bash
make clean
```

## Available Models

To see all available models and their status:

```bash
make list
```

This shows a table with:
- Model name
- Quantization method
- RAM requirements
- Build status
- Display name

## Model Configuration

Each model is defined by a YAML file in the `models/` directory. The Granite 4.1 8B model (`models/granite-4.1-8b-source.yaml`) includes:

```yaml
name: granite-4.1-8b-source
display_name: "IBM Granite 4.1 8B Instruct (Source)"
hf_repo: ibm-granite/granite-4.1-8b
source_type: safetensors
convert: true
quantization: Q4_K_M
context_length: 131072
chat_template: llama.cpp/models/templates/ibm-granite-granite-4.1.jinja
gguf_file: granite-4.1-8b-instruct-Q4_K_M.gguf
output: granite-4.1-8b-source-Q4_K_M.llamafile
```

### Configuration Fields

| Field | Description |
|-------|-------------|
| `name` | Internal model identifier |
| `display_name` | Human-readable model name |
| `hf_repo` | Hugging Face repository (e.g., `ibm-granite/granite-4.1-8b`) |
| `source_type` | Model format (`safetensors`, `pytorch`) |
| `convert` | Whether to convert from source (`true`) or download pre-built GGUF (`false`) |
| `quantization` | Quantization method (e.g., `Q4_K_M`, `Q5_K_M`, `Q6_K`) |
| `context_length` | Maximum context length in tokens |
| `chat_template` | Path to chat template file |
| `gguf_file` | Output GGUF filename |
| `output` | Final llamafile filename |

## Troubleshooting

### Common Issues

**Missing dependencies:**
```
ERROR: python3 is required but not found
```
Install Python 3.x from your package manager or [python.org](https://www.python.org/).

**PyTorch installation fails:**
```
ERROR: Failed to install torch
```
Ensure you're using the correct index URL:
```bash
uv pip install torch --extra-index-url https://download.pytorch.org/whl/cpu
```

**Out of memory during conversion:**
The FP16 conversion requires significant memory. For large models like Granite 4.1 8B, ensure you have at least 16GB of RAM available.

**llama.cpp clone fails:**
```
ERROR: Failed to clone llama.cpp
```
Check your git connectivity and try again. You can also manually clone it:
```bash
git clone https://github.com/ggml-org/llama.cpp.git --depth 1
```

### Architecture-Specific Notes

**aarch64 (Apple Silicon / ARM64):**
- aarch64 Linux requires registering the APE binary format once per boot:
```bash
sudo sh -c "echo ':APE:M::MZqFpD::/bin/sh:' > /proc/sys/fs/binfmt_misc/register"
```
- This is automatic on macOS

**Windows:**
- Use WSL2 (Windows Subsystem for Linux) for best compatibility
- Native Windows support is experimental

## Understanding the Process

### What Happens During Build

1. **Download**: Model weights are downloaded from Hugging Face Hub to `models-cache/`
2. **Convert**: Model is converted from safetensors to FP16 GGUF format using llama.cpp
3. **Template**: Custom chat template is applied for proper model interaction
4. **Context**: Context length is set (131,072 tokens for Granite 4.1 8B)
5. **Quantize**: FP16 GGUF is quantized to the target method (Q4_K_M by default)
6. **Package**: Quantized GGUF is bundled with the llamafile launcher using zipalign
7. **Test**: The final llamafile is verified to work correctly

### Output Files

| Directory | Purpose |
|-----------|---------|
| `tools/` | llamafile and zipalign binaries |
| `models-cache/` | Downloaded model weights and intermediate files |
| `llamafiles/` | Final generated Llamafiles |
| `.venv/` | Python virtual environment |
| `llama.cpp/` | Cloned llama.cpp repository (auto-downloaded) |

## Granite 4.1 8B Specifics

The IBM Granite 4.1 8B model built by Henry includes:

- **Extended context**: 131,072 tokens (128K+)
- **Features**: Tool calling, embedding, tagged content, function calling
- **Multilingual**: Supports multiple languages
- **Use cases**: Coding, RAG, AI assistant workflows
- **Quantization**: Q4_K_M (4-bit quantization with K and M matrices)
- **Memory**: ~6GB RAM required for inference

The custom chat template (`ibm-granite-granite-4.1.jinja`) enables:
- Proper instruction following
- Tool calling support
- Structured output formatting
- Multi-turn conversation handling

## Customization

### Create a Custom Model Configuration

To add a new model, create a YAML file in `models/`:

```yaml
name: my-custom-model
display_name: "My Custom Model"
hf_repo: my-org/my-model
source_type: safetensors
convert: true
quantization: Q5_K_M
context_length: 32768
chat_template: templates/my-template.jinja
gguf_file: my-model-Q5_K_M.gguf
output: my-model-Q5_K_M.llamafile
```

Then build it:
```bash
make all MODEL=my-custom-model
```

### Change Quantization Method

Edit the model YAML file and change the `quantization` field. Available methods include:
- `Q2_K` - 2-bit (smallest, lowest quality)
- `Q3_K_M` - 3-bit
- `Q4_0` - 4-bit original
- `Q4_K_M` - 4-bit with K and M matrices (recommended)
- `Q5_K_M` - 5-bit (better quality)
- `Q6_K` - 6-bit (higher quality)
- `Q8_0` - 8-bit (highest quality, largest)

Then rebuild:
```bash
make clean MODEL=granite-4.1-8b-source
make quantize MODEL=granite-4.1-8b-source
make package MODEL=granite-4.1-8b-source
```

## Resources

- **Henry Repository**: [https://github.com/rsdoiel/henry](https://github.com/rsdoiel/henry)
- **Mozilla Llamafile**: [https://github.com/Mozilla-Orin/llamafile](https://github.com/Mozilla-Orin/llamafile)
- **llama.cpp**: [https://github.com/ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- **IBM Granite 4.1 8B**: [https://huggingface.co/ibm-granite/granite-4.1-8b](https://huggingface.co/ibm-granite/granite-4.1-8b)
- **Hugging Face Hub**: [https://huggingface.co/](https://huggingface.co/)

## License

Henry is licensed under the AGPL-3.0 license. See [LICENSE](LICENSE) for details.
