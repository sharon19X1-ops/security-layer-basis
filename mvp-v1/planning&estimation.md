**Initial Plan**
Week 1–2 Infrastructure foundation: K8s cluster, Vault, NATS, RDS, mTLS PKI, CI/CD pipelines

Week 3–4 Hook Agent — VS Code extension skeleton + gRPC client + 8 event captures

Week 5–6 Hook Agent — CLI shim + PII strip + 72h local cache + interceptor batching

Week 5–8 Detection Engine Gateway: mTLS auth, rate limiting, tenant isolation, event dedup

Week 7–10 Event Pipeline: NATS → Normalizer → Rule Evaluator (all 7 rules) → Verdict Router

Week 7–12 ML Models: dataset curation → fine-tune → eval → ONNX export → runtime integration

Week 9–11 Skill Registry: SQLite schema + scoring engine (10 dimensions) + ingestion pipeline

Week 11–12 Integration Bus: ConnectWise PSA adapter + webhook engine + DLQ + retry backoff

Week 11–13 SOC Dashboard: event feed, alert triage, tenant management UI

Week 13–14 Installer script (OS detection, code signing, CDN publish, keystore write)

Week 13–14 Audit trail (immutable append-only log), policy hot-reload

Week 15–16 End-to-end integration testing, penetration test review, performance benchmarking

Week 16 MVP v1.0 go/no-go gate — launch to design partners


Critical path: ML models (Weeks 7–12) and Detection Engine (Weeks 5–10) run in parallel. Both must merge by Week 13 for integration testing.



**The estimates in brief**
Team: 7 people (2 Go devs, 1 TypeScript, 1 ML, 1 Frontend, 1 DevOps, 1 QA)
Timeline: 16 weeks / ~4 months

ML models (Weeks 7–12) and the detection engine (Weeks 5–10) are your critical path — both must merge by Week 13 for integration testing
The skill_intent_mismatch model dataset is the highest-risk item — start curating that at Week 1

Cloud hosting (AWS): could be via Free-Credits for MVP single-AZ

EKS (4× t3.xlarge), RDS PostgreSQL, ALB, CloudFront/S3 for the installer CDN, Vault on Kubernetes
Single Environment at the moment

**Key open-source tools defined**

Backend: Go + gRPC/protobuf + NATS + PostgreSQL + HashiCorp Vault + ONNX Runtime
Hook Agent: TypeScript + @grpc/grpc-js + better-sqlite3 (72h offline cache)
ML: PyTorch + HuggingFace Transformers (bert-base-uncased) + ONNX export
Infra: Kubernetes/EKS + Helm + cert-manager (mTLS) + Prometheus/Grafana/Loki
Security gates: Trivy (image scanning) + gitleaks (secret scanning in CI) + govulncheck
