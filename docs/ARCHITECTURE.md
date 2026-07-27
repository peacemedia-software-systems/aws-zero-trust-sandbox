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

3. Ephemeral Memory Lifecycle
​To prevent cross-session contamination and guarantee zero persistent footprint, the runtime handles payload data according to the following strict memory isolation flow:

[ Incoming Payload ] ──► [ Decrypted via BYOK KMS ] ──► [ Processed in /tmp (RAM) ] ──► [ Output Streamed ] ──► [ RAM Zeroed / Purged ]

1.​Ingress Isolation: Payloads arrive via encrypted TLS 1.3 tunnels and are held in volatile RAM buffers.
2. ​Volatile Mount: The execution runtime attaches an un-persisted, memory-backed file system (tmpfs allocated under /tmp).
3. ​Execution & Evaluation: Processing, API testing, or schema verification takes place inside volatile RAM.
​4. Memory Purge: Upon execution completion or container termination, memory pages are zero-overwritten (shred/srm) and
   freed back to the host system.

4. Key Security & Cryptographic Controls
​A. Bring Your Own Key (BYOK) Enclosure
​The sandbox requires an explicit AWS KMS Key ARN managed directly by the customer's SecOps team.
​The KMS key policy strictly limits kms:Decrypt and kms:GenerateDataKey actions exclusively to the execution role during the active evaluation window.
​Revoking or disabling the KMS key instantly halts all sandbox execution threads and renders in-flight RAM buffers unreadable.
​B. Audit Trail & Observability
​Immutable Logs: Standard output (stdout) and error streams (stderr) are piped directly to an encrypted AWS CloudWatch Log Group (/aws/sandbox/peacemedia-zero-trust-audit).
KMS Key Rotation: Audit log streams inherit the customer-managed KMS key policy.
​Audit Retention: Retention is set to 90 days by default to satisfy standard SOC 2 Type II and ISO 27001 logging requirements.

​5. Automated Stack Self-Destruction
​To enforce zero lingering infrastructure, an Amazon EventBridge Rule monitors the stack deployment timestamp:
{
  "Source": "aws.cloudformation",
  "DetailType": "CloudFormation Stack Status Change",
  "Detail": {
    "Status": "CREATE_COMPLETE",
    "StackName": "Peacemedia-ZeroTrust-Sandbox"
  }
}
▪︎ TTL Expiry Trigger: Upon reaching the defined EvaluationDurationDays parameter (Default: 30 days), EventBridge invokes
  an automated cleanup function.
▪︎ ​Teardown Execution: The stack initiates an aws cloudformation delete-stack cascade, purging IAM roles, security groups, temporary log streams, and ephemeral instances automatically.

## 6. Threat Model & Risk Mitigation Matrix

### Threat Vector 1: Data Exfiltration & Persistent Storage
* **Risk:** Unauthorized data persistence or lateral file writes during evaluation.
* **Mitigating Control:** Execution is mounted strictly to `/tmp` (`tmpfs` volatile RAM). Persistent block storage drivers (EBS/S3 volume mounts) are disabled.
* **Impact Level:** Critical (Mitigated)

### Threat Vector 2: IAM Privilege Escalation
* **Risk:** Un-sanitized sandbox execution role attempting to access external AWS resources.
* **Mitigating Control:** Execution role uses explicit least-privilege policies with zero wildcard (`"Resource": "*"`) permissions on enterprise data stores.
* **Impact Level:** High (Mitigated)

### Threat Vector 3: Un-Monitored Rogue Execution
* **Risk:** Hidden evaluation tasks running without security team visibility.
* **Mitigating Control:** Real-time CloudWatch stdout/stderr log streaming enforced with active BYOK KMS key encryption and SecOps alert hooks.
* **Impact Level:** Medium (Mitigated)

### Threat Vector 4: Lingering Shadow Infrastructure
* **Risk:** Abandoned sandbox environments remaining active indefinitely and incurring costs.
* **Mitigating Control:** Scheduled Amazon EventBridge rule automatically purges the stack and revokes temporary IAM credentials upon TTL expiration (default: 30 days).
* **Impact Level:** High (Mitigated)

7. Verification & Compliance Auditing
​Cloud Security Engineers can verify the sandbox boundary post-deployment using the AWS CLI:

# 1. Verify KMS Encryption Key Status
     aws kms describe-key --key-id <KmsKeyArnFromOutputs>
# 2. Inspect Audit Log Group Retention & Encryption
     aws logs describe-log-groups --log-group-name-prefix /aws/sandbox/peacemedia-zero-trust-audit
# 3. Confirm Ephemeral IAM Role Boundaries
     aws iam get-role-policy --role-name <ExecutionRoleFromOutputs> --policy-name VolatileExecutionAndAuditStreamPolicy
---
### Push File to GitHub

Run these terminal commands to commit the architecture doc to your repository:

```bash
git add docs/ARCHITECTURE.md
git commit -m "docs: add comprehensive technical architecture and memory specification"
git push origin main
