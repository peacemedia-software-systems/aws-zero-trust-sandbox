# 🛡️ AWS Zero-Trust Evaluation Sandbox (`aws-zero-trust-sandbox`)

Eliminate 60-day enterprise CISO review friction. Deploy a stateless, fully isolated evaluation gateway inside your prospect's private AWS VPC in under 30 seconds.

Launch Stack (https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateURL=https://raw.githubusercontent.com/peacemedia-software/aws-zero-trust-sandbox/main/peacemedia_sandbox_blueprint.json&stackName=Peacemedia-ZeroTrust-Sandbox)
AWS CloudFormation (https://img.shields.io/badge/AWS-CloudFormation-orange.svg)](https://aws.amazon.com/cloudformation/)
License: MIT (https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Core Architectural Features
🔒 **Volatile RAM Execution:** Processes third-party payloads exclusively in volatile memory (`/tmp` / `tmpfs`) — 0 bytes written to persistent disk storage.
* 🔑 **BYOK KMS Encryption:** Customer-controlled AWS KMS keys enforce strict cryptographic data boundary isolation.
* 🧹 **Automated Lifecycle Purge:** Scheduled Amazon EventBridge triggers auto-delete the CloudFormation stack and revoke temporary IAM roles upon evaluation expiry.
* 📋 **Audit Compliance:** Real-time immutable execution metadat
 streamed directly to the customer's private CloudWatch / S3 object-lock bucket.

## Quickstart (AWS CLI)
```bash
aws cloudformation create-stack \
  --stack-name peacemedia-sandbox-community \
  --template-body file://peacemedia_sandbox_blueprint.json \
  --capabilities CAPABILITY_IAM
