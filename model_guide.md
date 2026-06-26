---
title: Model Guide
---

# **Henry Model Catalog: Complete Guide to Available LLMs**

*Last updated: June 26, 2026*

This document describes all models with YAML definitions in Henry, including their capabilities, ideal use cases, and the hardware trade-offs for running each. Models are organized by family and sorted by parameter count.

## **📊 Quick Comparison Matrix**

| Model | Size | RAM | Context | Best For | Quantization |
|-------|------|-----|---------|----------|--------------|
| **Qwen 3.5 2B** | ~1.8 GB | 2GB+ | 32K | Lightweight chat, edge | Q8_0 |
| **Phi-4 Mini** | ~2.2 GB | 2GB+ | 128K | Structured reasoning, code | Q4_K_M |
| **Phi-3.5 Mini** | ~2.2 GB | 2GB+ | 128K | Multilingual reasoning, code | Q4_K_M |
| **SmolLM3 3B** | ~2.0 GB | 2GB+ | 128K | Hybrid reasoning, multilingual | Q4_K_M |
| **Apertus 4B** | ~2.3 GB | 2GB+ | 32K | Multilingual, tool calling | Q4_K_M |
| **Granite 4.1 3B** | ~2.4 GB | 2GB+ | 128K | Coding, RAG, assistants | Q4_K_M |
| **Llama 3.2 3B** | ~2.0-3.4 GB | 3-4GB+ | 128K | Multilingual, general use | Q4_K_M-Q8_0 |
| **Granite 3.3 8B** | ~4.9 GB | 6GB+ | 8K | Enterprise, function calling | Q4_K_M |
| **Gemma 4 E4B** | ~2.5 GB | 3GB+ | 128K | Technical docs, code review | Q4_K_M |
| **Qwen 3.5 4B** | ~2.5 GB | 3GB+ | 32K | General reasoning | Q5_K_S |
| **Qwen 3 4B** | ~2.7 GB | 3GB+ | 32K | General reasoning | Q5_K_S |
| **Apertus 8B** | ~4.9 GB | 6GB+ | 32K | Heavy multilingual | Q4_K_M |
| **Qwen 2.5 Coder 7B** | ~4.5 GB | 5GB+ | 32K | Code generation | Q4_K_M |
| **Llama 3 8B** | ~4.9-8.5 GB | 5-9GB+ | 8K | General chat, code | Q4_K_M-Q8_0 |
| **Granite 4.1 8B** | ~4.9 GB | 6GB+ | 128K | Enterprise assistants | Q4_K_M |
| **Granite 3.3 8B (Source)** | ~4.9 GB | 6GB+ | 128K | Custom tool workflows | Q4_K_M |
| **Gemma 3n E2B** | ~2.2 GB | 2GB+ | 128K | Compact reasoning, edge deployment | Q4_K_M |


## **🦙 Meta Llama Family**

### **Llama 3.2 Series** — Multilingual with Extended Context

The Llama 3.2 models feature **128K token context windows** and **native multilingual support** (English, German, French, Italian, Portuguese, Hindi, Spanish, Thai). They are instruction-tuned and support tool calling.

| Model | Quant | Size | RAM | Use Case | Trade-off |
|-------|-------|------|-----|----------|-----------|
| `llama-3.2-3b-instruct` | Q4_K_M | ~2.0 GB | 3GB+ | **Entry-level multilingual** — Good for basic chat, translation, and simple tool workflows on constrained hardware | Smallest file, moderate quality |
| `llama-3.2-3b-instruct-q5_k_m` | Q5_K_M | ~2.3 GB | 3GB+ | **Balanced multilingual** — Best price/performance for general use with 128K context | 15% larger than Q4, better accuracy |
| `llama-3.2-3b-instruct-q6_k_m` | Q6_K_M | ~2.6 GB | 3GB+ | **High-quality multilingual** — Uses Q8_0 for critical weights, near-perfect output | 30% larger than Q4, excellent quality |
| `llama-3.2-3b-instruct-q8_0` | Q8_0 | ~3.4 GB | 4GB+ | **Maximum quality** — Best for production where accuracy is paramount | Largest file, highest RAM |

**Best for:** Multilingual applications, long-document processing (128K context), chatbots serving international audiences, tool-enabled assistants on moderate hardware.


### **Llama 3 Series** — Proven General-Purpose Models

The original Llama 3 models with **8K token context**. Strong at instruction following, conversation, and code generation.

| Model | Quant | Size | RAM | Use Case | Trade-off |
|-------|-------|------|-----|----------|-----------|
| `llama-3-8b-instruct` | Q4_K_M | ~4.9 GB | 5GB+ | **Default choice** — Good balance for most users, strong general performance | Baseline quality, smallest footprint |
| `llama-3-8b-instruct-q5_k_m` | Q5_K_M | ~5.7 GB | 6GB+ | **Improved quality** — Better than Q4 for complex tasks, still reasonable size | 16% larger, better accuracy |
| `llama-3-8b-instruct-q6_k` | Q6_K | ~6.6 GB | 7GB+ | **High accuracy** — Near-perfect quality for most applications | 35% larger than Q4 |
| `llama-3-8b-instruct-q8_0` | Q8_0 | ~8.5 GB | 9GB+ | **Maximum fidelity** — Best for professional use where quality matters most | 73% larger than Q4, highest RAM |

**Best for:** General conversational AI, code assistance, API servers, applications where 8K context is sufficient.

**Note:** Llama 3 models lack the extended context and multilingual capabilities of Llama 3.2 but have been more thoroughly tested in production.


## **🪨 IBM Granite Family**

IBM's enterprise-oriented models with strong **tool calling, function calling, embedding, and tagged content** support. All Granite models support structured reasoning with `<think>` and `<response>` tags.

### **Granite 4.1 Series** — Next-Generation

| Model | Size | RAM | Context | Use Case | Trade-off |
|-------|------|-----|---------|----------|-----------|
| `granite-4.1-3b-source` | ~2.4 GB | 2GB+ | 128K | **Lightweight enterprise** — Coding, RAG, multilingual workflows on limited hardware | Small size, full 128K context |
| `granite-4.1-8b-source` | ~4.9 GB | 6GB+ | 128K | **Full enterprise** — Complex tool workflows, large documents, production assistants | Higher RAM, more capable |

**Best for:** Enterprise applications, RAG systems, AI assistants with complex tool integration, coding workflows.

### **Granite 3.3 Series** — Stable Release

| Model | Size | RAM | Context | Use Case | Trade-off |
|-------|------|-----|---------|----------|-----------|
| `granite-3.3-8b` | ~4.9 GB | 6GB+ | 8K | **Quick deployment** — Pre-built GGUF, fast setup, function calling ready | Limited context (8K) |
| `granite-3.3-8b-source` | ~4.9 GB | 6GB+ | 128K | **Custom tool workflows** — Built from source with extended context and full feature set | Requires conversion from source |

**Best for:** Business applications requiring function calling, structured outputs, and compliance-ready workflows.

**Granite features across all models:** `tool_calling`, `function_calling`, `embedding`, `tagged`


## **⛰️ Swiss-AI Apertus Family**

Open models from Swiss-AI with **EU AI Act compliance** and **1811 language support**.

| Model | Size | RAM | Context | Use Case | Trade-off |
|-------|------|-----|---------|----------|-----------|
| `apertus-4b` | ~2.3 GB | 2GB+ | 32K | **Lightweight multilingual** — 1811 languages, tool calling, embedding on minimal hardware | Smaller, distilled from 8B |
| `apertus-8b` | ~4.9 GB | 6GB+ | 32K | **Full multilingual** — Source model for 4B, more capable for complex multilingual tasks | 2x the RAM of 4B |

**Features:** `tool_calling`, `embedding`, `tagged`

**Best for:** Multilingual applications, European deployments requiring compliance, tool-enabled chatbots serving diverse language communities.

**Note:** Both use custom chat templates supporting `<tool_call>` tags.


## **🧠 HuggingFaceTB SmolLM3 Family**

Hugging Face's compact reasoning models with **hybrid reasoning mode** (extended thinking with `/think` and `/no_think` flags) and excellent **multilingual support**.

| Model | Size | RAM | Context | Use Case | Trade-off |
|-------|------|-----|---------|----------|-----------|
| `smollm3-3b` | ~2.0 GB | 2GB+ | 128K | **Compact reasoner** — Hybrid reasoning, multilingual (6+ languages), tool calling on minimal hardware | 3B parameters, excellent reasoning/parameter ratio |

**Features:** `tool_calling`

**Best for:** Applications requiring reasoning capabilities in a very compact package, multilingual deployments, hybrid reasoning workflows, tool-enabled assistants on resource-constrained hardware.

**Note:** Supports extended thinking mode via `/think` and `/no_think` flags in system prompt or `enable_thinking` parameter.


## **🌸 Google Gemma Family**

Google's efficient models optimized for on-device deployment.

| Model | Size | RAM | Context | Use Case | Trade-off |
|-------|------|-----|---------|----------|-----------|
| `gemma-3n-e2b-it` | ~2.2 GB | 2GB+ | 128K | **Compact reasoning** — Strong reasoning, coding, general conversational tasks on minimal hardware | E2B variant, 128K context, optimized for edge deployment |
| `gemma4-e4b` | ~2.5 GB | 3GB+ | 128K | **Technical documentation** — Code review, editorial tasks, technical writing with massive context | Efficient architecture, 128K context |

**Features:** `tool_calling`, `embedding`

**Best for:** Compact reasoning tasks, technical content generation, code review, documentation assistance, deployments on resource-constrained devices (runs on M1 Mac Mini with 8GB, Raspberry Pi 5 with 8GB RAM).

**Note:** Gemma 3n E2B uses the E2B (Efficient 2B) variant of the Gemma 3n architecture. Gemma 4 E4B uses the "Efficient" (E) series architecture, which is compact but highly capable.


## **🔍 Microsoft Phi Family**

Microsoft's reasoning-optimized models with exceptional **reasoning-per-parameter** ratios.

| Model | Size | RAM | Context | Use Case | Trade-off |
|-------|------|-----|---------|----------|-----------|
| `phi4-mini` | ~2.2 GB | 2GB+ | 128K | **Structured reasoning** — Code review, technical documentation, complex problem-solving | 3.8B parameters, best reasoning/parameter ratio |
| `phi-3.5-mini-instruct` | ~2.2 GB | 2GB+ | 128K | **Multilingual reasoning** — Strong multilingual (20+ languages), code, math, logic | 3.8B parameters, competitive reasoning |

**Features:** `tool_calling`

**Best for:** Applications requiring strong reasoning capabilities in a compact package, technical decision-making, code analysis, multilingual deployments.

**Note:** Phi-4 Mini can use either the embedded chat template from `tokenizer_config.json` or a Phi-3.5-mini fallback template.


## **🐉 Alibaba Qwen Family**

Alibaba's Qwen models, with specialized coding variants.

### **Qwen 3.5 Series**

| Model | Quant | Size | RAM | Context | Use Case | Trade-off |
|-------|-------|------|-----|---------|----------|-----------|
| `qwen3.5-2b` | Q8_0 | ~1.8 GB | 2GB+ | 32K | **Ultra-lightweight** — Minimal hardware, basic tool calling | Smallest Qwen, limited capability |
| `qwen3.5-4b` | Q5_K_S | ~2.5 GB | 3GB+ | 32K | **General purpose** — Good balance for most Qwen use cases | Mid-range size and capability |

**Best for:** Budget deployments, edge devices, simple chat applications.

### **Qwen 3 Series**

| Model | Quant | Size | RAM | Context | Use Case | Trade-off |
|-------|-------|------|-----|---------|----------|-----------|
| `qwen3-4b-instruct-2507` | Q5_K_S | ~2.7 GB | 3GB+ | 32K | **Latest checkpoint** — July 2025 model with improved capabilities over 3.5 series | Newer model, better general reasoning |

**Best for:** Users wanting the latest Qwen improvements for general reasoning tasks.

### **Qwen 2.5 Coder Series** — Coding Specialists

| Model | Quant | Size | RAM | Context | Use Case | Trade-off |
|-------|-------|------|-----|---------|----------|-----------|
| `qwen2.5-coder-7b` | Q4_K_M | ~4.5 GB | 5GB+ | 32K | **Code generation** — Strong on Go, TypeScript, and many other languages | Specialized for coding, less general knowledge |

**Features:** `tool_calling`

**Best for:** Code completion, code explanation, code generation across multiple programming languages, IDE integrations.

**Note:** File naming may vary in the GGUF repo (check Hugging Face for exact casing).


## **🎯 Resource Requirement Tiers**

### **Tier 1: Ultra-Lightweight (2GB RAM)**

*Can run on: Raspberry Pi 5 (8GB), M1 Mac Mini (8GB), budget laptops*

| Model | Use Case |
|-------|----------|
| Qwen 3.5 2B | Basic chat, simple tool calling |
| Phi-4 Mini | Structured reasoning, technical tasks |
| Phi-3.5 Mini | Multilingual reasoning, code, math, logic |
| SmolLM3 3B | Hybrid reasoning, multilingual, tool calling |
| Apertus 4B | Multilingual chat, 1811 languages |
| Granite 4.1 3B (Source) | Coding, RAG, enterprise workflows |
| Llama 3.2 3B (Q4_K_M) | Multilingual, 128K context |
| Gemma 3n E2B | Compact reasoning, edge deployment, tool calling |

**Best choice:** Phi-4 Mini for reasoning, Llama 3.2 3B for multilingual, Phi-3.5 Mini for multilingual reasoning, SmolLM3 3B for hybrid reasoning, Apertus 4B for language coverage, Gemma 3n E2B for compact reasoning on edge devices.


### **Tier 2: Lightweight (4GB RAM)**

*Can run on: Most modern laptops, M1 MacBook Air, mid-range desktops*

| Model | Use Case |
|-------|----------|
| Llama 3.2 3B (Q5_K_M-Q8_0) | High-quality multilingual |
| Qwen 3.5 4B | General reasoning |
| Qwen 3 4B Instruct (2507) | Latest Qwen improvements |
| Granite 4.1 3B (Source) | Enterprise workflows |
| Gemma 4 E4B | Technical documentation |
| Phi-3.5 Mini | Multilingual reasoning, code, math |
| SmolLM3 3B | Hybrid reasoning, multilingual |
| Gemma 3n E2B | Compact reasoning, edge deployment |

**Best choice:** Llama 3.2 3B Q5_K_M for balanced multilingual performance, Phi-3.5 Mini for multilingual reasoning.


### **Tier 3: Standard (6-8GB RAM)**

*Can run on: M1 MacBook Pro, gaming laptops, workstations*

| Model | Use Case |
|-------|----------|
| Llama 3 8B (Q4_K_M-Q6_K) | General purpose, code, chat |
| Granite 3.3 8B / 4.1 8B | Enterprise, function calling |
| Apertus 8B | Heavy multilingual |
| Qwen 2.5 Coder 7B | Code generation |

**Best choice:** Llama 3 8B Q5_K_M for best balance, Granite 4.1 8B for enterprise tool workflows.

### **Tier 4: High-End (8GB+ RAM)**

*Can run on: M2 MacBook Pro, workstations, servers*

| Model | Use Case |
|-------|----------|
| Llama 3 8B Q8_0 | Maximum quality general use |
| All other models at higher quantizations | Best quality variants |

**Best choice:** Llama 3 8B Q8_0 for maximum quality, or any model at its highest quantization.

## **💡 Use Case Recommendations**

### **🔧 Coding & Development**

| Priority | Model | Why |
|----------|-------|-----|
| 1 | **Qwen 2.5 Coder 7B** | Specialized for code, strong on Go/TypeScript |
| 2 | **Granite 4.1 8B (Source)** | 128K context, tool calling for IDE integration |
| 3 | **Llama 3 8B Q5_K_M** | Strong general code assistance |
| 4 | **Phi-4 Mini** | Excellent reasoning for code review |
| 5 | **Phi-3.5 Mini** | Multilingual code reasoning |
| 5 | **SmolLM3 3B** | Hybrid reasoning for code tasks |
| 6 | **Gemma 3n E2B** | Compact reasoning for code on edge devices |

### **🌍 Multilingual Applications**

| Priority | Model | Why |
|----------|-------|-----|
| 1 | **Apertus 8B** | 1811 languages, EU compliant |
| 2 | **Phi-3.5 Mini** | 20+ languages, 128K context, strong reasoning |
| 3 | **Llama 3.2 3B Q5_K_M** | 9 languages, 128K context |
| 4 | **SmolLM3 3B** | 6+ languages, 128K context, hybrid reasoning |
| 5 | **Apertus 4B** | 1811 languages, minimal hardware |
| 6 | **Granite 4.1 3B/8B** | Multilingual support, enterprise features |

### **📄 Long Document Processing (128K Context)**

| Priority | Model | Why |
|----------|-------|-----|
| 1 | **Granite 4.1 8B (Source)** | 128K context, enterprise features |
| 2 | **Llama 3.2 3B Q5_K_M** | 128K context, multilingual, balanced |
| 3 | **Gemma 4 E4B** | 128K context, efficient architecture |
| 4 | **Phi-4 Mini** | 128K context, strong reasoning |
| 5 | **Phi-3.5 Mini** | 128K context, multilingual reasoning |
| 6 | **SmolLM3 3B** | 128K context, hybrid reasoning |
| 7 | **Granite 4.1 3B (Source)** | 128K context, lightweight |
| 8 | **Gemma 3n E2B** | 128K context, compact reasoning for edge |

### **🎯 General Chat & Assistants**

| Priority | Model | Why |
|----------|-------|-----|
| 1 | **Llama 3 8B Q5_K_M** | Proven, high quality, tool calling |
| 2 | **Llama 3.2 3B Q5_K_M** | 128K context, multilingual |
| 3 | **Granite 4.1 8B (Source)** | Enterprise features, 128K context |
| 4 | **Phi-4 Mini** | Strong reasoning in compact package |
| 5 | **Phi-3.5 Mini** | Multilingual reasoning, 128K context |
| 6 | **SmolLM3 3B** | Hybrid reasoning, multilingual, 128K context |

### **🔌 Tool Calling & Function Calling**

| Priority | Model | Features |
|----------|-------|----------|
| 1 | **Granite 4.1 8B (Source)** | `tool_calling`, `function_calling`, `embedding`, `tagged` |
| 2 | **Granite 3.3 8B (Source)** | Same as above, 128K context |
| 3 | **Apertus 8B** | `tool_calling`, `embedding`, `tagged`, 1811 languages |
| 4 | **Phi-3.5 Mini** | `tool_calling`, 128K context, 20+ languages |
| 5 | **SmolLM3 3B** | `tool_calling`, 128K context, hybrid reasoning |
| 6 | **Llama 3.2 3B Q6_K_M** | `tool_calling`, 128K context, multilingual |
| 7 | **Gemma 3n E2B** | `tool_calling`, 128K context, compact edge deployment |

### **💰 Budget Deployments**

| Priority | Model | Hardware | Capability |
|----------|-------|----------|------------|
| 1 | **Qwen 3.5 2B** | 2GB RAM | Basic tool calling, 32K context |
| 2 | **Phi-4 Mini** | 2GB RAM | Strong reasoning, 128K context |
| 3 | **Phi-3.5 Mini** | 2GB RAM | Multilingual reasoning, 128K context |
| 4 | **SmolLM3 3B** | 2GB RAM | Hybrid reasoning, multilingual, tool calling |
| 5 | **Apertus 4B** | 2GB RAM | 1811 languages, tool calling |
| 6 | **Gemma 3n E2B** | 2GB RAM | Compact reasoning, tool calling, 128K context |
| 7 | **Llama 3.2 3B Q4_K_M** | 3GB RAM | Multilingual, 128K context |

## **⚖️ Trade-off Summary**

### **Quantization Trade-offs**

| Quantization | File Size | Quality | RAM | Speed | Best For |
|--------------|-----------|---------|-----|-------|----------|
| Q4_K_M | Smallest (75% of Q8) | Good | Lower | Fastest | Budget deployments, testing |
| Q5_K_M | Moderate (+15-20%) | High | +1GB | Slightly slower | Best balance for most users |
| Q5_K_S | Moderate (+15-20%) | Very High | +1GB | Slightly slower | High-quality variants |
| Q6_K | Larger (+30-35%) | Very High | +1-2GB | Slower | Near-perfect quality |
| Q6_K_M | Larger (+30-35%) | Very High | +1-2GB | Slower | Uses Q8_0 for critical weights |
| Q8_0 | Largest (baseline) | Maximum | +2-3GB | Slowest | Production, maximum accuracy |

### **Model Size Trade-offs**

| Size | Pros | Cons |
|------|------|------|
| **2-3B** | Low RAM, fast, 128K context available | Less capable, limited complexity |
| **4-5B** | Good balance, 32-128K context | Moderate RAM, reasonable capability |
| **7-8B** | High capability, production-ready | Higher RAM (6-9GB), larger files |

### **Context Length Trade-offs**

| Context | Pros | Cons |
|---------|------|------|
| **8K** | Lower RAM, faster | Can't process long documents |
| **32K** | Good for most documents | Moderate RAM increase |
| **128K** | Full books, long conversations | Higher RAM, slower |

## **🏆 Top Picks by Scenario**

| Scenario | Best Model | Runner-Up | Budget Option |
|----------|------------|-----------|---------------|
| **Best overall** | Llama 3 8B Q5_K_M | Llama 3.2 3B Q5_K_M | Llama 3.2 3B Q4_K_M |
| **Best for coding** | Qwen 2.5 Coder 7B | Granite 4.1 8B (Source) | Phi-3.5 Mini |
| **Best multilingual** | Apertus 8B | Phi-3.5 Mini | Llama 3.2 3B Q5_K_M |
| **Best for long docs** | Granite 4.1 8B (Source) | Llama 3.2 3B Q5_K_M | Phi-3.5 Mini |
| **Best reasoning** | Phi-4 Mini | Phi-3.5 Mini | Llama 3 8B Q6_K |
| **Best enterprise** | Granite 4.1 8B (Source) | Granite 3.3 8B (Source) | Apertus 8B |
| **Best for edge** | Phi-4 Mini | Phi-3.5 Mini | Gemma 3n E2B |
| **Lowest RAM** | Qwen 3.5 2B (2GB) | Phi-4 Mini (2GB) | Phi-3.5 Mini (2GB) / Gemma 3n E2B (2GB) |

## **📦 Model Type Key**

| Field | Description |
|-------|-------------|
| **`convert: true`** | Model must be converted from source (safetensors) to GGUF |
| **`source_type: safetensors`** | Model is in PyTorch safetensors format, not pre-converted GGUF |
| **`chat_template`** | Custom template used for conversation formatting |
| **`features`** | Capabilities baked into the GGUF: `tool_calling`, `function_calling`, `embedding`, `tagged` |
| **`kind: instruct`** | Instruction-tuned model (follows prompts better) |
| **`ram_gb`** | Recommended minimum RAM for comfortable operation |
| **`context_length`** | Maximum token context window |

