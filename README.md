# AWS VPC + EC2 + Docker via Terraform and GitHub Actions

## How it works
Push to `main` -> GitHub Actions:
1. Builds `app/` into a Docker image and pushes it to Docker Hub (tag = commit SHA).
2. Runs Terraform: creates VPC, subnet, internet gateway, route table, security group and an EC2 instance.
3. EC2 boot script (`terraform/user_data.sh`) installs Docker and runs your image on port 80.
4. The app URL appears in the workflow run summary.

Each new push changes the image tag, so Terraform replaces the EC2 instance and it runs the new image.

## One-time setup

### 1. AWS: IAM user for GitHub
- IAM -> Users -> Create user (e.g. `github-actions`).
- Attach policy `AmazonEC2FullAccess` and `AmazonS3FullAccess`
  (fine for learning; tighten later).
- Security credentials -> Create access key -> copy Access Key ID and Secret.

### 2. AWS: S3 bucket for Terraform state
Bucket names are globally unique. In AWS CloudShell or with AWS CLI:

    aws s3api create-bucket --bucket YOUR-UNIQUE-STATE-BUCKET --region ap-south-1 \
      --create-bucket-configuration LocationConstraint=ap-south-1
    aws s3api put-bucket-versioning --bucket YOUR-UNIQUE-STATE-BUCKET \
      --versioning-configuration Status=Enabled

### 3. Docker Hub
Create an account, then Account Settings -> Security -> New Access Token (Read & Write).

### 4. GitHub secrets
Repo -> Settings -> Secrets and variables -> Actions -> New repository secret:

| Secret | Value |
|---|---|
| AWS_ACCESS_KEY_ID | from step 1 |
| AWS_SECRET_ACCESS_KEY | from step 1 |
| TF_STATE_BUCKET | your bucket name from step 2 |
| DOCKERHUB_USERNAME | your Docker Hub username |
| DOCKERHUB_TOKEN | token from step 3 |

### 5. Push
    git init && git add . && git commit -m "first commit"
    git branch -M main
    git remote add origin https://github.com/YOU/REPO.git
    git push -u origin main

Open the Actions tab. When finished, open the run summary for the URL
(wait 1-2 minutes after apply for Docker to start on the instance).

## Clean up (avoid charges)
Actions tab -> "Destroy Infrastructure" -> Run workflow.

## Notes
- Region is `ap-south-1` (Mumbai). Change it in the workflows and `variables.tf`.
- Docker Hub image must be public (or add `docker login` to `user_data.sh`).
- Next steps: OIDC instead of access keys, SSM access instead of SSH, ALB, ECR.
