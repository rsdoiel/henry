# ONNXfile — Concept Idea

**Status:** Concept only — not being pursued at this time.  
**Date:** 2026-06-29  
**Related:** [unified-models-design.md](../harvey/unified-models-design.md) (ONNX appendix)

---

## The Idea

An ONNXfile would be a self-contained, portable executable that bundles an
ONNX model, the ONNX Runtime C/C++ library, a tokenizer, and a lightweight
HTTP server — analogous to what Mozilla AI's llamafile does for GGUF chat
models. The structural parallel is direct:

```
llamafile:
  llama.cpp (C/C++) compiled with cosmocc  →  launcher binary
  zipalign(launcher + model.gguf)           →  model.llamafile

onnxfile:
  ONNX Runtime (C/C++) compiled with cosmocc  →  launcher binary
  zipalign(launcher + model.onnx + tokenizer.json)  →  model.onnxfile
```

The launcher binary extracts or mmaps the bundled model from itself at
startup, initialises ONNX Runtime, loads the tokenizer, and serves an
OpenAI-compatible HTTP API (`/v1/embeddings`). The result is a single
executable per model with zero runtime dependencies, running on Linux
x86/ARM64, macOS x86/ARM64, and Windows from one fat APE binary.

The primary target is **encoder/embedding models**, not generative models.
Generative ONNX inference requires a full auto-regressive loop with KV
cache management — llama.cpp/GGUF already handles that case better. The
ONNXfile value proposition is for embedding models where llamafile has no
clean story today.

---

## Why C/C++ + Cosmopolitan, Not Go

A Go-based approach using `onnxruntime-purego` (which calls ONNX Runtime
via `dlopen` rather than CGo) was considered. It keeps Harvey's pure-Go
cross-compilation intact but is not truly self-contained: users still need
`libonnxruntime.so`/`.dylib`/`.dll` installed at runtime, and the
portability advantage disappears. The C/C++ + Cosmopolitan path delivers
the actual llamafile guarantee: one binary, zero setup.

---

## Henry's Role

Henry is the right home for this. The work splits into two phases:

**Phase A — build the launcher binary (novel engineering):**  
A C/C++ project (`onnxfile-server`) that compiles ONNX Runtime, a
tokenizer implementation, and a lightweight HTTP server under `cosmocc`.
This would live in `henry/onnxfile/` similarly to how `henry/llama.cpp/`
is a vendored sub-tree. Once built, this binary is the stable tool that
gets zipaligned with models — analogous to the `llamafile` binary Henry
downloads from Mozilla.

**Phase B — per-model factory (trivial once Phase A exists):**  
Add `output_type: onnxfile` to a model YAML. The pipeline is: download
ONNX model from HuggingFace → zipalign with the launcher binary → done.
This is a small Makefile addition matching the existing pattern.

Mable's role (when it reaches that stage): train an encoder model, export
via `torch.onnx.export` + `optimum`, hand off `.onnx` + `tokenizer.json`
to Henry's factory.

Harvey's role: consume the ONNXfile via the existing `EncoderfileEmbedder`
and `any-llm-go` without code changes — it is just another local HTTP URL.

---

## Key Technical Risks

**Porting ONNX Runtime to cosmocc** is the central obstacle and the reason
this is deferred. ONNX Runtime is a large C++17 codebase with:

- Heavy CMake and many platform-specific `#ifdef` branches that conflict
  with Cosmopolitan's "compile once, detect at runtime" model
- Third-party dependencies (Abseil, Protobuf, re2, Eigen) each requiring
  their own cosmocc port
- Hardware accelerator backends (CoreML, DirectML, CUDA) that are
  incompatible with a static portable binary — CPU-only inference only

llamafile itself required months of engineering effort to port llama.cpp
to Cosmopolitan. ONNX Runtime is comparable in scope. The right first step
before committing to the factory design is a minimal build experiment:
compile ONNX Runtime's CPU execution provider as a static library under
cosmocc and verify correctness on two targets (Linux x86_64 and macOS
ARM64). If that succeeds, Phase A is unblocked.

**Tokenization** is a secondary obstacle. The launcher binary must
tokenize raw text into token IDs using the model's `tokenizer.json`.
C++ options include `sentencepiece` and several community BPE
implementations. Coverage of the full HuggingFace tokenizers spec varies;
this needs evaluation against the specific embedding models targeted.

---

## Trigger for Revisiting

Revisit this concept if any of the following occur:

- A third party successfully ports ONNX Runtime to Cosmopolitan libc
  (reducing Phase A from a research project to an integration task)
- Mable produces an encoder model worth distributing (creating a concrete
  model to package)
- Harvey's embedding story requires wider deployment scenarios where
  requiring ONNX Runtime as a runtime dependency is unacceptable
