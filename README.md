# AWS Terraform CI/CD Pipeline

This project builds an AWS CI/CD system for Terraform using CodePipeline, CodeBuild, S3, DynamoDB, IAM, and GitHub CodeStar Connections.

The repository contains three main parts:

- `aws-devops-core/`: verifies the existing S3 bucket and DynamoDB table used for Terraform remote state.
- `modules/module-aws-tf-cicd/`: reusable Terraform code that creates the CI/CD pipelines and supporting AWS resources.
- `example-production-workload/`: example root configuration that calls the reusable CI/CD module.

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

The module creates two pipelines:

1. Module validation pipeline: validates the Terraform module repository.
2. Deployment pipeline: validates and applies the workload repository.

## Project Structure

```text
AWS-CICD-PIPELINE/
├── README.md
├── aws-devops-core/
│   └── main.tf
├── example-production-workload/
│   └── main.tf
├── pipeline-deployment/
│   └── main.tf
└── modules/
    └── module-aws-tf-cicd/
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

## Prerequisites

Install and configure these before running the project:

- Terraform `>= 1.6`
- AWS CLI
- An AWS account with permission to create S3, DynamoDB, IAM, CodeBuild, CodePipeline, and CodeStar/CodeConnections resources
- A configured AWS CLI profile or environment variables
- GitHub repositories for the module and workload code
- A GitHub CodeStar Connection created in AWS

Verify your local tools:

```bash
terraform version
aws sts get-caller-identity
```

## Important Values To Change

This project is configured for your existing backend in `us-west-2`:

- S3 bucket: `baho-backup-bucket`
- Backend key prefix: `Codepipeline-backup/`
- DynamoDB lock table: `full-devops-table`

You originally shared the backend as `baho-backup-bucket/Codepipeline-backup`. In Terraform backend syntax, that is split into `bucket = "baho-backup-bucket"` and `key = "Codepipeline-backup/<state-file-name>.tfstate"`.

Before deploying, review these values and replace only the ones that differ from your AWS account and GitHub repositories:

- `pipeline-deployment/main.tf`
  - S3 backend `bucket`
  - S3 backend `key`
  - backend `region`
  - backend `dynamodb_table`
- `example-production-workload/main.tf`
  - S3 backend `bucket`
  - S3 backend `key`
  - backend `region`
  - backend `dynamodb_table`
  - `github_repo_module`
  - `github_repo_workload`
  - `artifacts_bucket_name`
  - `state_bucket_name`
  - `dynamodb_table_name`

S3 bucket names are global across all AWS accounts. If a bucket name is already taken, choose a unique name.
The backend lock table and the pipeline-created lock table should stay different. This README uses your existing `full-devops-table` for Terraform backend locking and `baho-pipeline-state-lock` for pipeline-managed Terraform state locking.

## Step 1: Create A GitHub CodeStar Connection

This step is manual in the AWS Console.

1. Open AWS Console.
2. Go to CodePipeline.
3. Open Settings, then Connections.
4. Create a new GitHub connection.
5. Authorize the GitHub app.
6. Allow access to the module and workload repositories.
7. Copy the connection ARN.

The ARN looks similar to this:

```text
arn:aws:codestar-connections:us-west-2:123456789012:connection/abc123
```

## Step 2: Confirm Terraform Remote State

You already have the backend resources, so this project is configured to use them. Confirm they exist with AWS CLI:

```bash
aws s3api head-bucket --bucket baho-backup-bucket --region us-west-2
aws dynamodb describe-table --table-name full-devops-table --region us-west-2
```

You can also verify them through the `aws-devops-core` Terraform root:

```bash
cd aws-devops-core
terraform init
terraform plan
```

## Step 3: Update Backend Configuration

`pipeline-deployment/main.tf` is already configured with your backend.

Example:

```hcl
backend "s3" {
  bucket         = "baho-backup-bucket"
  key            = "Codepipeline-backup/module-aws-tf-cicd/terraform.tfstate"
  region         = "us-west-2"
  dynamodb_table = "full-devops-table"
  encrypt        = true
}
```

`example-production-workload/main.tf` is also already configured to use the same backend bucket/table with its own state key.

## Step 4: Deploy The CI/CD Module

From the pipeline deployment root:

```bash
cd pipeline-deployment
terraform init
terraform validate
terraform plan \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
terraform apply \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
```

Terraform will create:

- CodePipeline artifact bucket
- Terraform state bucket
- DynamoDB state lock table
- IAM roles and policies
- CodeBuild projects
- CodePipeline pipelines

## Step 5: Run Local Terraform Checks

Format check:

```bash
terraform fmt -recursive
```

Validate the backend verification root:

```bash
cd aws-devops-core
terraform init -backend=false
terraform validate
```

Validate the CI/CD module:

```bash
cd modules/module-aws-tf-cicd
terraform init -backend=false
terraform validate
```

Run Terraform tests:

```bash
cd modules/module-aws-tf-cicd
terraform test -verbose
```

The included tests use `plan`, so they validate structure without applying AWS resources.

## Step 6: Run Checkov Locally

Install Checkov if needed:

```bash
pip3 install checkov
```

Run the scan:

```bash
cd modules/module-aws-tf-cicd
checkov --directory . --framework terraform
```

## Step 7: Run TFLint Locally

Install TFLint if needed:

```bash
brew install tflint
```

Run linting:

```bash
cd modules/module-aws-tf-cicd
tflint --recursive
```

## Step 8: Deploy The Example Workload

The example root configuration calls the reusable module with production-style values.

```bash
cd example-production-workload
terraform init
terraform validate
terraform plan \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
terraform apply \
  -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"
```

## Pipeline Behavior

After deployment, pushes to the configured GitHub branch can trigger the pipelines through the CodeStar/CodeConnections source action.

Current defaults:

- Branch: `main`
- Module repo: `Joebaho/module-aws-tf-cicd`
- Workload repo: `Joebaho/example-prod-workload`
- Region: `us-west-2`

Change these before running if your repositories or region are different.

## Readiness Notes

This project has the main files needed for a Terraform-based AWS CI/CD pipeline. The Terraform files are formatted, and the structure matches the intended project.

Before running in AWS, review these items:

- Confirm that all S3 bucket names are unique in AWS.
- Confirm the GitHub repository names are correct.
- Confirm the CodeStar Connection ARN is active.
- Decide whether `example-production-workload/` should create a second copy of the CI/CD pipeline or whether it is only an example.
- Review IAM permissions in `modules/module-aws-tf-cicd/iam.tf`; the CodeBuild role currently has broad permissions so Terraform can provision infrastructure.
- The PDF lists manual approval and SNS notifications as optional next steps; those are not implemented yet.

## Cleanup

To destroy resources created by this project, destroy in reverse order:

```bash
cd example-production-workload
terraform destroy -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"

cd ../pipeline-deployment
terraform destroy -var="codestar_connection_arn=YOUR_CODESTAR_CONNECTION_ARN"

cd ../aws-devops-core
terraform destroy
```

If S3 buckets contain objects or versions, Terraform may not be able to delete them until the bucket contents are removed.
