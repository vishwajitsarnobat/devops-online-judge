pipeline {
    agent any

    tools {
        nodejs "node20" 
    }

    environment {
        S_URL   = credentials('supabase-url')
        S_KEY   = credentials('supabase-key')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/vishwajitsarnobat/devops-online-judge.git'
            }
        }

        stage('Install and Test') {
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }

        stage('Generate Configs') {
            steps {
                sh """
                set -eu

                cat > .env <<EOF
SUPABASE_URL=${S_URL}
SUPABASE_SERVICE_ROLE_KEY=${S_KEY}
PORT=3000
VITE_API_BASE=http://localhost:3000
EOF

                cat > inventory.ini <<EOF
[local]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
EOF
                """
            }
        }

        stage('Deploy') {
            steps {
                sh "ansible-playbook -i inventory.ini deploy.yml"
            }
        }
    }
}