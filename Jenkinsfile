pipeline {
    agent any

    tools {
        nodejs "node20"
    }

    environment {
        // Credentials stored securely in Jenkins — never in code
        S_URL          = credentials('supabase-url')
        S_KEY          = credentials('supabase-key')
        DOCKERHUB      = credentials('dockerhub-creds')   // username + password
        AWS_CREDS      = credentials('aws-creds')          // access key + secret
        DOCKER_USER    = 'vishwajitsarnobat'
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    triggers {
        // GitHub webhook — Jenkins receives POST at /github-webhook/
        githubPush()
    }

    stages {
        // ================================================================
        // Stage 1: Checkout — pull latest code from GitHub
        // ================================================================
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/vishwajitsarnobat/devops-online-judge.git'
            }
        }

        // ================================================================
        // Stage 2: Install & Test — run unit tests
        // If tests fail, the pipeline stops here. Bad code never reaches
        // production.
        // ================================================================
        stage('Install and Test') {
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }

        // ================================================================
        // Stage 3: Build Docker Images
        // Each image gets two tags:
        //   - BUILD_NUMBER (e.g. :42) — for rollback to specific version
        //   - latest — for convenience
        // ================================================================
        stage('Build Docker Images') {
            steps {
                sh """
                    docker build \
                        -t ${DOCKER_USER}/online-judge-backend:${IMAGE_TAG} \
                        -t ${DOCKER_USER}/online-judge-backend:latest \
                        .

                    docker build \
                        -t ${DOCKER_USER}/online-judge-frontend:${IMAGE_TAG} \
                        -t ${DOCKER_USER}/online-judge-frontend:latest \
                        --build-arg VITE_API_BASE=http://\$(cd terraform && terraform output -raw ec2_public_ip 2>/dev/null || echo localhost):3000 \
                        ./frontend
                """
            }
        }

        // ================================================================
        // Stage 4: Push to Docker Hub
        // Uses the dockerhub-creds credential (username/password type).
        // DOCKERHUB_USR and DOCKERHUB_PSW are auto-created by Jenkins
        // from the credentials() binding above.
        // ================================================================
        stage('Push to Docker Hub') {
            steps {
                sh """
                    echo "${DOCKERHUB_PSW}" | docker login -u "${DOCKERHUB_USR}" --password-stdin

                    docker push ${DOCKER_USER}/online-judge-backend:${IMAGE_TAG}
                    docker push ${DOCKER_USER}/online-judge-backend:latest

                    docker push ${DOCKER_USER}/online-judge-frontend:${IMAGE_TAG}
                    docker push ${DOCKER_USER}/online-judge-frontend:latest
                """
            }
        }

        // ================================================================
        // Stage 5: Terraform — create/update AWS infrastructure
        // terraform init connects to S3 backend.
        // terraform apply creates the EC2 instance (or does nothing if
        // it already exists — idempotent).
        // ================================================================
        stage('Terraform Apply') {
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}",
                    "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}",
                    "AWS_DEFAULT_REGION=ap-south-1"
                ]) {
                    sh """
                        cd terraform
                        terraform init -input=false
                        terraform apply -auto-approve -input=false
                    """
                }
            }
        }

        // ================================================================
        // Stage 6: Ansible — deploy to EC2
        // 1. Read the EC2 IP from Terraform output
        // 2. Generate inventory.ini with that IP
        // 3. Write the SSH key to a temp file
        // 4. Run the Ansible playbook
        // ================================================================
        stage('Deploy with Ansible') {
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}",
                    "AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}",
                    "AWS_DEFAULT_REGION=ap-south-1"
                ]) {
                    withCredentials([file(credentialsId: 'ec2-ssh-key', variable: 'SSH_KEY_FILE')]) {
                        sh """
                            set -eu

                            # Get EC2 public IP from Terraform
                            EC2_IP=\$(cd terraform && terraform output -raw ec2_public_ip)

                            echo "Deploying to EC2 at \${EC2_IP}..."

                            # Generate Ansible inventory with the EC2 IP
                            cat > inventory.ini <<INVENTORY
[webservers]
\${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_FILE}
INVENTORY

                            # Generate .env for the remote server
                            cat > .env <<ENVFILE
SUPABASE_URL=${S_URL}
SUPABASE_SERVICE_ROLE_KEY=${S_KEY}
PORT=3000
DOCKER_USER=${DOCKER_USER}
IMAGE_TAG=${IMAGE_TAG}
VITE_API_BASE=http://\${EC2_IP}:3000
ENVFILE

                            # Run Ansible playbook
                            ansible-playbook -i inventory.ini deploy.yml \
                                -e "docker_user=${DOCKER_USER}" \
                                -e "image_tag=${IMAGE_TAG}" \
                                -e "supabase_url=${S_URL}" \
                                -e "supabase_key=${S_KEY}" \
                                -e "docker_hub_user=${DOCKERHUB_USR}" \
                                -e "docker_hub_pass=${DOCKERHUB_PSW}"
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            sh """
                EC2_IP=\$(cd terraform && terraform output -raw ec2_public_ip 2>/dev/null || echo 'unknown')
                echo ""
                echo "=========================================="
                echo "  ✅ DEPLOYMENT SUCCESSFUL"
                echo "  Frontend: http://\${EC2_IP}:5173"
                echo "  Backend:  http://\${EC2_IP}:3000"
                echo "  Health:   http://\${EC2_IP}:3000/health"
                echo "=========================================="
            """
        }
        failure {
            echo '❌ Pipeline failed. Check the stage logs above for details.'
        }
        always {
            // Clean up Docker login credentials from the build agent
            sh 'docker logout || true'
        }
    }
}