# Terraform CI/CD and Testing on AWS

Automated Terraform testing and deployment using AWS CodePipeline, CodeBuild, S3, DynamoDB, and GitHub via CodeStar Connections.

---

## Architecture

```
GitHub (push) → CodeStar Connection → CodePipeline
                                          │
                          ┌───────────────┼───────────────┐
                          ▼               ▼               ▼
                     TF Test         Checkov Scan       TFLint        TF Apply
                   (CodeBuild)       (CodeBuild)      (CodeBuild)    (CodeBuild)
                       │                 │                │              │
                       └────────────── S3 State + DynamoDB Lock ────────┘
```

**Two Pipelines:**
1. **Module Validation Pipeline** — Source → TF Test → Checkov → TFLint
2. **Deployment Pipeline** — Source → TF Test → Checkov → TFLint → Apply

---

## Project Structure

```
terraform-cicd/
├── aws-devops-core/                  # Verifies existing S3 + DynamoDB backend
│   └── main.tf
├── example-production-workload/      # Root module calling the reusable module
│   └── main.tf
├── pipeline-deployment/              # Root module that deploys the CI/CD module
│   └── main.tf
└── modules/
    └── module-aws-tf-cicd/           # Reusable CICD module
        ├── codebuild.tf
        ├── codepipeline.tf
        ├── data.tf
        ├── iam.tf
        ├── outputs.tf
        ├── s3.tf
        ├── variables.tf
        ├── versions.tf
        ├── buildspec/
        │   ├── checkov-buildspec.yml
        │   ├── tf-apply-buildspec.yml
        │   ├── tf-test-buildspec.yml
        │   └── tflint-buildspec.yml
        └── tests/
            └── main.tftest.hcl
```

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.6.0
- GitHub repositories created
- AWS CodeStar Connection to GitHub (created in AWS Console)

---

## Step-by-Step Deployment

### Step 1 — Create CodeStar Connection (Manual, one-time)

1. Go to **AWS Console → CodePipeline → Settings → Connections**
2. Click **Create connection** → Select **GitHub**
3. Authorize the AWS Connector for GitHub app
4. Select your repositories: `module-aws-tf-cicd` and `example-prod-workload`
5. Copy the **Connection ARN** — you'll need it below

### Step 2 — Confirm the Remote Backend

```bash
aws s3api head-bucket --bucket baho-backup-bucket --region us-west-2
aws dynamodb describe-table --table-name full-devops-table --region us-west-2
```

### Step 3 — Update backend configuration

In `pipeline-deployment/main.tf`, update the backend bucket name with the output from Step 2:
```hcl
backend "s3" {
  bucket         = "baho-backup-bucket"
  key            = "Codepipeline-backup/module-aws-tf-cicd/terraform.tfstate"
  region         = "us-west-2"
  dynamodb_table = "full-devops-table"
  encrypt        = true
}
```

### Step 4 — Deploy the Module

```bash
cd pipeline-deployment
terraform init
terraform plan -var="codestar_connection_arn=arn:aws:codestar-connections:..."
terraform apply -var="codestar_connection_arn=arn:aws:codestar-connections:..."
```

### Step 5 — Run Terraform Tests Locally

```bash
cd modules/module-aws-tf-cicd
terraform init
terraform test -verbose
# Expected: 2 passed, 0 failed
```

### Step 6 — Run Checkov Locally

```bash
pip install checkov
checkov --directory . --framework terraform
# Expected: Passed checks > 90, Failed checks: 0
```

### Step 7 — Run TFLint Locally

```bash
brew install tflint    # macOS
tflint --recursive
```

### Step 8 — Deploy Example Production Workload

```bash
cd example-production-workload
terraform init
terraform apply -var="codestar_connection_arn=YOUR_ARN"
```

---

## Pipeline Trigger

Once deployed, every `git push` to the `main` branch of either GitHub repo will automatically trigger the corresponding pipeline.

---

## Services Used

| Service | Purpose |
|---|---|
| AWS CodePipeline | CI/CD pipeline orchestration |
| AWS CodeBuild | Terraform tests, Checkov scan, TFLint, Apply |
| S3 | Artifact store + remote state backend |
| DynamoDB | Terraform state locking |
| IAM | Roles for CodePipeline and CodeBuild |
| GitHub + CodeStar | Source trigger via webhook |

---

## Key Learnings from this Project

- CodeStar Connections replace CodeCommit for GitHub integration
- Remote state must exist before using it as a backend
- `terraform test` requires Terraform >= 1.6
- Checkov `--soft-fail` allows pipeline to continue with warnings
- Modular Terraform means one reusable module, multiple root configurations
