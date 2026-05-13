# POC Plan: Hook Security Platform

##  POC Objective
To demonstrate the **End-to-End flow**: *Developer Action → Hook Interception → Policy Verdict → SOC Dashboard* using a minimal footprint.

## POC Scope (Minimal Cover)
Based on the SD update, we are focusing on a high-impact, low-friction mockup to prove the core value proposition.

### 1. The Components
* **The Hook (CLI Shim):** A Go-based wrapper that intercepts `kubectl` or `git` commands.
* **The Relay (Backend):** A lightweight Go service on EKS to receive events and run basic rule checks.
* **The SOC Mockup (UI):** A single-page dashboard showing a real-time "Security Event Feed."
* **Infrastructure:** AWS EKS environment with shared Admin access.

---

##  Resource Allocation (Revised)
| Role | Responsibility |
| :--- | :--- |
| **Sankalp (Lead)** | AWS/EKS Infrastructure, IAM/Security, Frontend Dashboard |
| **Go Developer 1** | CLI Shim development (The Hook) & gRPC transport |
| **Go Developer 2** | Backend Relay Service & PostgreSQL logic |

---

## ⏱ POC Execution Roadmap (2-Week Sprint)

### Week 1: Infrastructure & Data Path
* **Day 1-2: Cloud Foundation**
    * Setup AWS EKS Cluster, RDS (Postgres), and IAM Roles.
    * *Deliverable:* Admin credentials shared with Stakeholder.
* **Day 3-5: The Hook (Agent)**
    * Develop the Go shim to intercept CLI commands.
    * Implement basic PII stripping (local).
    * *Deliverable:* Functional binary that wraps `kubectl`.

### Week 2: Logic & Visualization
* **Day 6-8: Detection Gateway**
    * Go service to ingest hooks.
    * Hardcoded "Risk Engine" (e.g., flag any command containing `secret`).
* **Day 9-10: SOC Mockup UI**
    * React-based live feed showing intercepted events.
    * *Deliverable:* URL to the live POC dashboard.

---

##  Tech Stack for POC
* **Cloud:** AWS (EKS, RDS)
* **Languages:** Go (Shim/Backend), TypeScript (Frontend)
* **Communication:** gRPC
* **Storage:** PostgreSQL

---

##  Success Metrics for POC
1.  **Latency:** Interception adds < 200ms to the developer's command execution.
2.  **Visibility:** Event appears in the SOC Dashboard within 5 seconds of command execution.
3.  **Security:** Evidence of mTLS between the Hook and the Relay.
