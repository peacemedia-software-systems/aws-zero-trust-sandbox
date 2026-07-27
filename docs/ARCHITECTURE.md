# 🏗️ Technical Architecture & Memory Model Specification

> **Document Version:** 2.0.0  
> **Target Audience:** Lead Cloud Architects, CISOs, SecOps Teams  
> **Maintainer:** Peacemedia Systems  

---

## 1. Architectural Philosophy

The **Peacemedia Zero-Trust Evaluation Sandbox** provides an isolated, ephemeral runtime environment inside a customer's private AWS perimeter. It allows third-party B2B software, API payloads, and integrations to be audited and evaluated **without persistent data liability**.

### Core Guiding Principles:
* **Zero Persistence:** Data processing occurs strictly in volatile RAM (`tmpfs` / `/tmp`). No data is written to EBS volumes, S3 buckets, or non-volatile block storage.
* **Cryptographic Boundary:** All evaluation memory buffers and temporary state variables are encrypted using Customer-Managed Keys (CMK) via AWS KMS.
* **Least-Privilege IAM:** Ephemeral execution roles contain zero broad wildcards (`"Resource": "*"`) for data access services.
* **Deterministic Self-Destruction:** Automated lifecycle hooks purge the stack, revoke credentials, and clean up network interfaces after evaluation expiry.

---

## 2. Infrastructure Architecture Diagram

```text
               ┌──────────────────────────────────────────────────────────┐
               │ CUSTOMER AWS ACCOUNT / PRIVATE VPC                       │
               │                                                          │
               │  ┌────────────────────────────────────────────────────┐  │
               │  │ Isolated Private Subnet (No Public IP Route)       │  │
               │  │                                                    │  │
               │  │  ┌──────────────────────────────────────────────┐  │  │
               │  │  │ Ephemeral Sandbox Container / Compute        │  │  │
               │  │  │                                              │  │  │
 Payload ───►  │  │  │  ┌────────────────────────────────────────┐  │  │  │
 (TLS 1.3)     │  │  │  │ Volatile RAM Buffer (/tmp)              │  │  │  │
               │  │  │  │ • 0 Byte Persistent Disk Storage      │  │  │  │
               │  │  │  │ • Process Memory Wiped on Termination  │  │  │  │
               │  │  │  └──────────────────┬─────────────────────┘  │  │  │
               │  │  └─────────────────────┼────────────────────────┘  │  │
               │  └────────────────────────┼───────────────────────────┘  │
               │                           │                              │
               │      ┌────────────────────┴─────────────────────┐        │
               │      ▼                                          ▼        │
               │ ┌─────────┐                            ┌──────────────┐  │
               │ │ AWS KMS │ (BYOK Encryption Keys)     │ CloudWatch   │  │
               │ └─────────┘                            │ Audit Stream │  │
               │                                        └──────────────┘  │
               └──────────────────────────────────────────────────────────┘
