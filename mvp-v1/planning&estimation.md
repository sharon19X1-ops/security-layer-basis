
# Project Roadmap: Hook Security Platform (MVP)

---

## 📅 Timeline Overview
* **Total Duration:** 16 Weeks (~4 Months)
* **Team Composition:** 7 Members
    * 2× Go Developers (Backend/Core)
    * 1× TypeScript Developer (Hook Agent)
    * 1× ML Engineer (Models/Inference)
    * 1× Frontend Developer (SOC Dashboard)
    * 1× DevOps Engineer (Infrastructure/CI/CD)
    * 1× QA Engineer (Testing/Pen-testing)

---

## 🚀 Execution Phases

### Phase 1: Foundation (Weeks 1–4)
* **Weeks 1–2: Infrastructure & DevOps**
    * Setup **K8s (EKS)** cluster, **HashiCorp Vault**, **NATS**, and **RDS**.
    * Establish mTLS PKI and CI/CD pipelines (Trivy, gitleaks).
* **Weeks 3–4: Hook Agent Alpha**
    * VS Code extension skeleton + gRPC client.
    * Implementation of the first 8 event captures.

### Phase 2: Core Development (Weeks 5–8)
* **Weeks 5–6: Agent Hardening**
    * CLI shim development and **PII stripping** logic.
    * Local 72h SQLite cache + interceptor batching.
* **Weeks 5–8: Detection Engine Gateway**
    * mTLS authentication, rate limiting, and tenant isolation.
    * Event deduplication logic.

### Phase 3: Intelligence & Logic (Weeks 7–12)
* **Weeks 7–10: Event Pipeline**
    * NATS → Normalizer → Rule Evaluator (7 core rules) → Verdict Router.
* **Weeks 7–12: ML Model Development (Critical Path)**
    * Dataset curation (Starting Week 1) → Fine-tuning → Evaluation.
    * **ONNX export** and runtime integration.
* **Weeks 9–11: Skill Registry**
    * SQLite schema + 10-dimension scoring engine.
    * Ingestion pipeline for developer skills.

### Phase 4: Integration & Delivery (Weeks 11–16)
* **Weeks 11–12: Integration Bus**
    * ConnectWise PSA adapter, webhook engine, and DLQ (Dead Letter Queue).
* **Weeks 11–13: SOC Dashboard**
    * Frontend UI for event feeds, alert triage, and tenant management.
* **Weeks 13–14: Distribution & Audit**
    * Installer scripts (OS detection, code signing, CDN publish).
    * Immutable append-only audit logs and policy hot-reload.
* **Weeks 15–16: Validation**
    * End-to-end integration, penetration testing, and performance benchmarking.
* **Week 16: MVP Launch**
    * Go/No-Go gate and release to design partners.

---

## 🛠 Tech Stack

| Component | Technology |
| :--- | :--- |
| **Backend** | Go, gRPC/Protobuf, NATS, PostgreSQL |
| **Hook Agent** | TypeScript, `@grpc/grpc-js`, `better-sqlite3` |
| **ML/AI** | PyTorch, HuggingFace (BERT), ONNX Runtime |
| **Security** | HashiCorp Vault, cert-manager (mTLS), Trivy, gitleaks |
| **Infrastructure** | AWS (EKS, RDS, S3), Helm, Prometheus, Grafana |

---

## ⚠️ Risk Management & Critical Path
* **The Critical Path:** The **ML Models (W7-12)** and **Detection Engine (W5-10)** must merge by Week 13. Any delay here pushes the MVP launch.
* **High-Risk Item:** The `skill_intent_mismatch` dataset is the most difficult to source. **Data curation must begin in Week 1.**
* **Infrastructure:** Initial MVP will run on a single-AZ (Availability Zone) using AWS Free Credits to minimize burn.

---
