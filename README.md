# AWS Terraform CI/CD Pipeline

This project provisions an AWS CI/CD system for Terraform using GitHub, CodeStar Connections, CodePipeline, CodeBuild, S3, DynamoDB, IAM, KMS, Checkov, and TFLint.

The project is configured for `us-west-2` and uses an existing Terraform backend:

- S3 bucket: `baho-backup-bucket`
- State key prefix: `Codepipeline-backup/`
- Backend locking: S3 native lockfile

In Terraform backend syntax, `baho-backup-bucket/Codepipeline-backup` is split into:

```hcl
bucket = "baho-backup-bucket"
key    = "Codepipeline-backup/<state-file>.tfstate"
```

## Architecture

```text
GitHub push
   |
   v
CodeStar Connection
   |
   v
CodePipeline
   |
   +--> CodeBuild: terraform test
   +--> CodeBuild: Checkov scan
   +--> CodeBuild: TFLint
   +--> CodeBuild: terraform apply
   |
   v
S3 remote state + DynamoDB locking
```

The reusable module creates two pipelines:

1. Module validation pipeline: validates the Terraform module repository.
2. Deployment pipeline: validates and applies the workload repository.

## Project Structure

```text
AWS-CICD-PIPELINE/
├── README.md
├── aws-devops-core/
│   ├── main.tf              # Reads the existing backend bucket
│   ├── outputs.tf
│   ├── providers.tf
│   └── variables.tf
├── pipeline-deployment/
│   ├── main.tf              # Deploys the reusable CI/CD module
│   ├── outputs.tf
│   ├── providers.tf         # S3 backend for pipeline state
│   └── variables.tf
├── example-production-workload/
│   ├── main.tf              # Example root module using the CI/CD module
│   ├── outputs.tf
│   ├── providers.tf         # S3 backend for example workload state
│   └── variables.tf
└── modules/
    └── module-aws-tf-cicd/
        ├── buildspec/
        │   ├── checkov-buildspec.yml
        │   ├── tf-apply-buildspec.yml
        │   ├── tf-test-buildspec.yml
        │   └── tflint-buildspec.yml
        ├── tests/
        │   └── main.tftest.hcl
        ├── codebuild.tf
        ├── codepipeline.tf
        ├── data.tf
        ├── iam.tf
        ├── kms.tf
        ├── outputs.tf
        ├── s3.tf
        ├── variables.tf
        └── versions.tf
```

## What Gets Created

Deploying `pipeline-deployment/` creates:

- Two CodePipeline pipelines
- Four CodeBuild projects:
  - Terraform test
  - Checkov scan
  - TFLint scan
  - Terraform apply
- CodePipeline artifact S3 bucket
- Terraform state S3 bucket for pipeline-managed workloads
- DynamoDB lock table for pipeline-managed state
- Customer-managed KMS key and alias
- IAM roles and inline policies for CodePipeline and CodeBuild

The existing backend bucket `baho-backup-bucket` is not recreated. Terraform state is stored in that bucket and protected with S3 native lockfiles.

## Prerequisites

Install and configure:

- Terraform `>= 1.6`
- AWS CLI
- Checkov
- TFLint
- GitHub repositories for the module and workload code
- A GitHub CodeStar Connection in `us-west-2`
- AWS permissions to create CodePipeline, CodeBuild, S3, DynamoDB, IAM, KMS, and CodeStar/CodeConnections resources

Verify your local environment:

```bash
terraform version
aws sts get-caller-identity
```

## Step 1: Confirm The Existing Backend

From the project root:

```bash
aws s3api head-bucket \
  --bucket baho-backup-bucket \
  --region us-west-2

```

Expected result: the S3 command returns no error.

You can also verify the backend with Terraform:

```bash
cd aws-devops-core
terraform init
terraform plan
```

Expected result: Terraform reads the existing bucket and table through data sources.

## Step 2: Create Or Confirm The CodeStar Connection

In the AWS Console:

1. Open CodePipeline.
2. Go to Settings.
3. Open Connections.
4. Create or select a GitHub connection.
5. Make sure it is in `us-west-2`.
6. Authorize access to your GitHub repositories.
7. Copy the connection ARN.

Example ARN:

```text
arn:aws:codestar-connections:us-west-2:123456789012:connection/abc123
```

## Step 3: Review Deployment Variables

Open `pipeline-deployment/variables.tf` and confirm these values:

- `aws_region`: defaults to `us-west-2`
- `github_repo_module`: defaults to `Joebaho/module-aws-tf-cicd`
- `github_repo_workload`: defaults to `Joebaho/example-prod-workload`
- `github_branch`: defaults to `main`
- `artifacts_bucket_name`: defaults to `baho-codepipeline-artifacts`
- `state_bucket_name`: defaults to `baho-pipeline-tf-state`
- `dynamodb_table_name`: defaults to `baho-pipeline-state-lock`

Change the GitHub repository values if your real repositories have different names.

The deployment backend is in `pipeline-deployment/providers.tf`:

```hcl
backend "s3" {
  bucket       = "baho-backup-bucket"
  key          = "Codepipeline-backup/module-aws-tf-cicd/terraform.tfstate"
  region       = "us-west-2"
  encrypt      = true
  use_lockfile = true
}
```

## Step 4: Deploy The CI/CD Pipelines

From the project root:

```bash
cd pipeline-deployment
terraform init
terraform validate
terraform plan \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
```

If the plan looks correct:

```bash
terraform apply \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
```

Expected result:

- Terraform creates the CI/CD pipelines and supporting AWS resources.
- Terraform state is stored at:
  - `s3://baho-backup-bucket/Codepipeline-backup/module-aws-tf-cicd/terraform.tfstate`
- State locking uses:
  - `s3://baho-backup-bucket/Codepipeline-backup/module-aws-tf-cicd/terraform.tfstate.tflock`

Check outputs:

```bash
terraform output
```

Expected outputs include:

- `module_validation_pipeline_name`
- `deployment_pipeline_name`
- `artifacts_bucket_name`
- `state_bucket_name`
- `kms_key_arn`

## Step 5: Run Local Quality Checks

From the project root:

```bash
terraform fmt -recursive
```

Validate the reusable module:

```bash
cd modules/module-aws-tf-cicd
terraform init -backend=false
terraform validate
terraform test -verbose
```

Run Checkov:

```bash
checkov --directory . --framework terraform
```

Expected result after the latest hardening:

```text
Failed checks: 0
```

Some checks may show as skipped because this single-region lab intentionally does not enable S3 access logging, S3 event notifications, or cross-region replication.

Run TFLint:

```bash
tflint --recursive
```

Expected result:

```text
0 issues
```

## Step 6: Trigger The Pipelines

After `pipeline-deployment` is applied, push code to the configured GitHub branch:

```text
main
```

Expected result:

- CodePipeline starts automatically from the CodeStar source action.
- The module validation pipeline runs Terraform test, Checkov, and TFLint.
- The deployment pipeline runs Terraform test, Checkov, TFLint, and Terraform apply.

## Optional: Deploy The Example Workload

The `example-production-workload/` root module also calls the reusable CI/CD module. Use it only if you intentionally want another CI/CD stack with production-style names.

Its backend is configured in `example-production-workload/providers.tf`:

```hcl
backend "s3" {
  bucket       = "baho-backup-bucket"
  key          = "Codepipeline-backup/example-prod-workload/terraform.tfstate"
  region       = "us-west-2"
  encrypt      = true
  use_lockfile = true
}
```

Run:

```bash
cd example-production-workload
terraform init
terraform validate
terraform plan \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
terraform apply \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
```

Expected result: Terraform deploys a second CI/CD stack using the same reusable module.

## Cleanup

Destroy resources in reverse order.

If you deployed the optional example workload:

```bash
cd example-production-workload
terraform destroy \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
```

Destroy the main pipeline deployment:

```bash
cd ../pipeline-deployment
terraform destroy \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
```

Do not destroy `aws-devops-core` unless you intentionally want to remove or stop using the existing backend resources. In this refactor, `aws-devops-core` only reads the existing backend resources.

## Notes

- The CodeBuild role intentionally has broad permissions because the pipeline runs Terraform apply.
- The backend uses S3 native lockfiles. The pipeline-managed Terraform state table is separate and defaults to `baho-pipeline-state-lock`.
- The module uses a customer-managed KMS key for CodeBuild, CodePipeline artifacts, S3 bucket encryption, and DynamoDB encryption.
- Manual approval and SNS notifications are optional future enhancements.

## 🤝 Contribution

Pull requests are welcome. For major changes, please open an issue first.

## 👨‍💻 Author

**Joseph Mbatchou**

• DevOps / Cloud / Platform  Engineer   
• Content Creator / AWS Builder

## 🔗 Connect With Me

🌐 Website: [https://platform.joebahocloud.com](https://platform.joebahocloud.com)

💼 LinkedIn: [https://www.linkedin.com/in/josephmbatchou/](https://www.linkedin.com/in/josephmbatchou/)

🐦 X/Twitter: [https://www.twitter.com/Joebaho237](https://www.twitter.com/Joebaho237)

▶️ YouTube: [https://www.youtube.com/@josephmbatchou5596](https://www.youtube.com/@josephmbatchou5596)

🔗 Github: [https://github.com/Joebaho](https://github.com/Joebaho)

📦 Dockerhub: [https://hub.docker.com/u/joebaho2](https://hub.docker.com/u/joebaho2)

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.
