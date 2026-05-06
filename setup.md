# CI/CD Pipeline — Walkthrough

## What Was Done

### New Files Created (7)

| File | Purpose |
|------|---------|
| [provider.tf](file:///home/vishwajit/Workspace/devops-online-judge/terraform/provider.tf) | AWS provider + S3 backend for Terraform state |
| [variables.tf](file:///home/vishwajit/Workspace/devops-online-judge/terraform/variables.tf) | Configurable inputs (region, instance type, AMI, Docker user) |
| [main.tf](file:///home/vishwajit/Workspace/devops-online-judge/terraform/main.tf) | Security group (ports 22/3000/5173) + EC2 instance with Docker user_data |
| [outputs.tf](file:///home/vishwajit/Workspace/devops-online-judge/terraform/outputs.tf) | Exports EC2 public IP for Ansible |
| [setup-s3-backend.sh](file:///home/vishwajit/Workspace/devops-online-judge/scripts/setup-s3-backend.sh) | One-time script to create S3 bucket for Terraform state |
| [docker-compose.prod.yml](file:///home/vishwajit/Workspace/devops-online-judge/docker-compose.prod.yml) | Production compose — pulls pre-built images from Docker Hub |

### Modified Files (4)

| File | Change |
|------|--------|
| [Jenkinsfile](file:///home/vishwajit/Workspace/devops-online-judge/Jenkinsfile) | Full 6-stage pipeline: checkout → test → build → push → terraform → ansible |
| [deploy.yml](file:///home/vishwajit/Workspace/devops-online-judge/deploy.yml) | Rewritten for remote EC2 deploy via SSH (was local Podman) |
| [ansible.cfg](file:///home/vishwajit/Workspace/devops-online-judge/ansible.cfg) | Updated for remote SSH connections to EC2 |
| [.gitignore](file:///home/vishwajit/Workspace/devops-online-judge/.gitignore) | Added Terraform state files and lock file |

---

## Your Next Steps (Manual Setup)

These are one-time setup steps you do before running the pipeline for the first time:

### Step 1: AWS CLI
```bash
aws configure
# Access Key ID:     (from AWS Console → IAM → Security Credentials)
# Secret Access Key: (same)
# Region:            ap-south-1
# Output:            json
```

### Step 2: Create EC2 Key Pair
```bash
aws ec2 create-key-pair \
  --key-name online-judge-key \
  --query 'KeyMaterial' \
  --output text > online-judge-key.pem
chmod 400 online-judge-key.pem
```

### Step 3: Create S3 Bucket
```bash
cd /home/vishwajit/Workspace/devops-online-judge
bash scripts/setup-s3-backend.sh
```

### Step 4: Initialize Terraform
```bash
cd terraform
terraform init
```

### Step 5: Docker Hub
1. Create account at https://hub.docker.com (username: `vishwajitsarnobat`)
2. Create access token: Account Settings → Security → New Access Token
3. Create repos: `online-judge-backend` and `online-judge-frontend`

### Step 6: Jenkins Credentials
Add these 5 credentials in Jenkins (Manage Jenkins → Credentials → Global):

| ID | Type | Value |
|----|------|-------|
| `supabase-url` | Secret text | Your Supabase URL |
| `supabase-key` | Secret text | Your Supabase service role key |
| `dockerhub-creds` | Username/Password | Docker Hub user + access token |
| `aws-creds` | Username/Password | AWS Access Key ID + Secret Key |
| `ec2-ssh-key` | Secret file | Upload `online-judge-key.pem` |

### Step 7: Create Jenkins Pipeline Job
1. In the Jenkins Dashboard, click **New Item**.
2. Name it `online-judge-pipeline`, select **Pipeline**, and click **OK**.
3. Under **Build Triggers**, check the box for **GitHub hook trigger for GITScm polling**.
4. Under the **Pipeline** section:
   - **Definition**: Select `Pipeline script from SCM`
   - **SCM**: Select `Git`
   - **Repository URL**: Your GitHub repository URL (e.g., `https://github.com/vishwajitsarnobat/devops-online-judge.git`)
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile`
5. Click **Save**.

### Step 8: Ngrok + GitHub Webhook
```bash
ngrok http 8080
# Copy the HTTPS URL (e.g. https://abc123.ngrok-free.app)
```
Then in GitHub → repo → Settings → Webhooks → Add:
- Payload URL: `https://abc123.ngrok-free.app/github-webhook/`
- Content type: `application/json`
- Events: Just the push event

### Step 9: Run!
Push any commit to `main` and watch Jenkins run the full pipeline.
