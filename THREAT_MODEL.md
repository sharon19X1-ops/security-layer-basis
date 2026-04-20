# Security Layer-Basis — Threat Model

**Version:** 0.1  
**Date:** 2026-04-19

---

## Threat Classes

### 1. Prompt Injection
**What:** Attacker embeds instructions in code, comments, or data that hijack the AI agent's behavior.  
**Variants:** Direct text, leet-speak substitution, Unicode lookalikes, base64-encoded payloads, multi-step chained injections.  
**Detection:** Pattern library with obfuscation variant expansion + fine-tuned BERT classifier.  
**Verdict:** BLOCK

### 2. Credential Exfiltration via Shell
**What:** AI agent is manipulated into running shell commands that read secrets (`.env`, private keys, cloud tokens) and transmit them externally.  
**Detection:** Shell event regex matching file reads of secret-shaped paths combined with network egress.  
**Verdict:** BLOCK + SOC ALERT

### 3. Reverse Shell Injection
**What:** AI-generated code or completions contain reverse shell payloads that call back to attacker-controlled infrastructure.  
**Detection:** Regex on shell patterns (`bash -i`, `nc -e`, `/dev/tcp`) + ML classifier on code AST features.  
**Verdict:** KILL_SESSION + PAGERDUTY

### 4. Unauthorized MCP Server Connections
**What:** AI agent connects to a malicious or unauthorized Model Context Protocol server, potentially leaking context or receiving adversarial instructions.  
**Detection:** MCP connect events checked against approved server allowlist.  
**Verdict:** BLOCK

### 5. Supply Chain Attacks via Compromised Dependencies
**What:** AI agent suggests or installs packages that have been compromised (typosquatting, hijacked maintainer accounts, malicious updates).  
**Detection:** Package name + version checked against live threat intel feed (npm, PyPI, Maven, Go).  
**Verdict:** WARN (known risk) → BLOCK (confirmed malicious)

---

## Trust Boundaries

| Boundary | Trust Level | Notes |
|----------|-------------|-------|
| Developer machine | Untrusted | IDE hook runs here; no detection logic |
| Local Interceptor Agent | Semi-trusted | Strips PII; authenticated via mTLS cert |
| Detection Engine | Trusted | All policy evaluation; SOC-controlled |
| Policy Store | High-trust | Git-signed; change requires SOC approval |
| Audit Trail | High-trust | Immutable; SOC read-only in production |

---

## Out of Scope (v1)

- Insider threat from privileged SOC operators (separate control)
- Physical access to developer machines
- Attacks on the Detection Engine infrastructure itself (handled by infra security)
