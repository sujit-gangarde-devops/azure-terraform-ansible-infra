// Terraform + Ansible pipeline: static checks -> plan -> manual approval -> apply -> configure -> verify
//
// Jenkins credentials needed:
//   azure-sp            Azure Service Principal (Azure Credentials plugin)
//   tfvars-<env>        Secret file: environments/<env>/terraform.tfvars
//   tf-backend-<env>    Secret file: environments/<env>/backend.hcl
//   azure-vm-ssh        SSH Username with private key (user: azureuser)

def withAzure(Closure body) {
    withCredentials([azureServicePrincipal(
        credentialsId: 'azure-sp',
        subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
        clientIdVariable: 'ARM_CLIENT_ID',
        clientSecretVariable: 'ARM_CLIENT_SECRET',
        tenantIdVariable: 'ARM_TENANT_ID'
    )]) {
        body()
    }
}

pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'uat', 'prod'], description: 'Target environment')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'plan only, apply changes, or destroy everything')
    }

    environment {
        TF_DIR            = "environments/${params.ENVIRONMENT}"
        TF_IN_AUTOMATION  = 'true'
        TF_INPUT          = 'false'
        ANSIBLE_FORCE_COLOR = 'true'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Static Checks') {
            steps {
                sh 'terraform fmt -check -recursive'
                dir(env.TF_DIR) {
                    sh 'terraform init -backend=false && terraform validate'
                }
                sh 'tflint --init && tflint --recursive'
                // Security scan of the Terraform code; report only, don't block the lab
                sh 'checkov -d . --framework terraform --quiet --soft-fail'
                dir('ansible') {
                    sh 'ansible-lint playbooks/site.yml || true'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    file(credentialsId: "tfvars-${params.ENVIRONMENT}", variable: 'TFVARS'),
                    file(credentialsId: "tf-backend-${params.ENVIRONMENT}", variable: 'BACKEND')
                ]) {
                    withAzure {
                        dir(env.TF_DIR) {
                            sh '''
                                terraform init -reconfigure -backend-config="$BACKEND"
                                DESTROY_FLAG=""
                                if [ "$ACTION" = "destroy" ]; then DESTROY_FLAG="-destroy"; fi
                                terraform plan $DESTROY_FLAG -var-file="$TFVARS" -out=tfplan
                                terraform show -no-color tfplan > tfplan.txt
                            '''
                        }
                    }
                }
                archiveArtifacts artifacts: "${env.TF_DIR}/tfplan.txt"
            }
        }

        stage('Approval') {
            when { expression { params.ACTION != 'plan' } }
            steps {
                input message: "${params.ACTION.toUpperCase()} this plan on ${params.ENVIRONMENT}? Review tfplan.txt first.", ok: 'Yes, go ahead'
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION != 'plan' } }
            steps {
                withAzure {
                    dir(env.TF_DIR) {
                        sh 'terraform apply tfplan'
                    }
                }
            }
        }

        stage('Ansible Configure') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'azure-vm-ssh', keyFileVariable: 'SSH_KEY')]) {
                    dir('ansible') {
                        sh '''
                            ansible-galaxy collection install -r requirements.yml
                            ansible-playbook playbooks/site.yml -i inventory/$ENVIRONMENT.ini --private-key "$SSH_KEY"
                        '''
                    }
                }
            }
        }

        stage('Verify') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                withAzure {
                    dir(env.TF_DIR) {
                        sh '''
                            URL=$(terraform output -raw app_url)
                            for i in 1 2 3 4 5 6; do
                                if curl -fsS "$URL/health"; then echo "Healthy: $URL"; exit 0; fi
                                sleep 10
                            done
                            echo "App did not become healthy at $URL"; exit 1
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            dir(env.TF_DIR) {
                sh 'rm -f tfplan'
            }
        }
    }
}
