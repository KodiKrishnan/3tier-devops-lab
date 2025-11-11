// Jenkinsfile (Declarative) - multibranch pipeline for EKS + Terraform + Docker + K8s
// Assumptions:
// - Jenkins is configured with credentials referenced below (IDs shown).
// - Agents have docker, terraform, awscli, kubectl installed OR you use Kubernetes agents with appropriate containers.
// - Repo layout: terraform/, k8s_manifests/, frontend/, backend/

pipeline {
  agent any

  // Fail fast if any parallel branch fails
  options {
    buildDiscarder(logRotator(numToKeepStr: '50'))
    disableConcurrentBuilds()
    timestamps()
    ansiColor('xterm')
    timeout(time: 60, unit: 'MINUTES')
  }

  environment {
    // Fill these in Jenkins credentials configuration
    AWS_REGION = credentials('AWS_REGION') // optional text credential if you store region
    AWS_CREDENTIALS = 'aws-creds'         // Jenkins AWS credentials (access key ID / secret) - see runbook
    ECR_REGISTRY = "public.ecr.aws/w8u5e4v2" // change to your ECR registry (public or private)
    TF_WORKING_DIR = "terraform"
    K8S_NAMESPACE = "workshop"
    // Image tags based on commit
    GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    IMAGE_TAG = "${env.BRANCH_NAME}-${env.GIT_COMMIT_SHORT}"
    // Credential IDs
    GIT_CREDENTIALS_ID = 'git-creds'
    DOCKER_CREDS = 'ecr-docker-creds' // optional if pushing to private ecr with auth plugin
    SLACK_CREDENTIALS = 'slack-webhook-url' // optional
  }

  parameters {
    booleanParam(name: 'APPLY_INFRA', defaultValue: false, description: "If true, run `terraform apply` (requires approval on main).")
    booleanParam(name: 'DEPLOY_MONITORING', defaultValue: false, description: "If true, deploy Prometheus/Grafana stack after app deploy.")
    choice(name: 'ACTION', choices: ['plan','apply','destroy'], description: "Terraform action to run (plan/apply/destroy).")
  }

  triggers {
    // For multibranch this could be disabled; keep minimal triggers
    // pollSCM('H/5 * * * *')
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        script {
          echo "Branch: ${env.BRANCH_NAME}, Commit: ${env.GIT_COMMIT}"
        }
      }
    }

    stage('Pre-flight Static Checks') {
      parallel {
        stage('Terraform fmt/validate') {
          steps {
            dir("${TF_WORKING_DIR}") {
              sh '''
                terraform fmt -check || { echo "Run terraform fmt to fix formatting"; exit 1; }
                terraform init -input=false -no-color
                terraform validate
              '''
            }
          }
        }
        stage('Security scans (fast)') {
          parallel {
            stage('tfsec (terraform scan)') {
              steps {
                dir("${TF_WORKING_DIR}") {
                  sh '''
                    if command -v tfsec >/dev/null 2>&1; then
                      tfsec .
                    else
                      echo "tfsec not installed on agent - skipping tfsec"
                    fi
                  '''
                }
              }
            }
            stage('npm audit (frontend)') {
              steps {
                dir('frontend') {
                  sh '''
                    if [ -f package.json ]; then
                      npm ci --silent
                      npm audit --audit-level=high || echo "npm audit found issues (non-fatal in this pipeline)"
                    else
                      echo "No frontend package.json - skip"
                    fi
                  '''
                }
              }
            }
          }
        }
      }
    }

    stage('Terraform Plan') {
      when { expression { params.ACTION == 'plan' || params.ACTION == 'apply' } }
      steps {
        dir("${TF_WORKING_DIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
            sh '''
              set -euo pipefail
              terraform init -input=false -no-color
              terraform workspace select ${BRANCH_NAME} || terraform workspace new ${BRANCH_NAME}
              terraform plan -out=tfplan -input=false -no-color
              terraform show -json tfplan > tfplan.json || true
            '''
            archiveArtifacts artifacts: "${TF_WORKING_DIR}/tfplan.json", fingerprint: true, allowEmptyArchive: true
            // Publish plan as build artifact for review
          }
        }
      }
    }

    stage('Manual Approval for Infra Apply') {
      when {
        allOf {
          expression { return env.BRANCH_NAME == 'main' }
          expression { return params.ACTION == 'apply' }
        }
      }
      steps {
        script {
          // require human approval in main
          timeout(time: 1, unit: 'HOURS') {
            input message: "Approve terraform apply to ${env.BRANCH_NAME} for ${env.GIT_COMMIT_SHORT}?", ok: 'Approve'
          }
        }
      }
    }

    stage('Terraform Apply or Destroy') {
      when { expression { params.ACTION == 'apply' || params.ACTION == 'destroy' } }
      steps {
        dir("${TF_WORKING_DIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
            script {
              if (params.ACTION == 'apply') {
                sh '''
                  terraform init -input=false -no-color
                  terraform workspace select ${BRANCH_NAME} || terraform workspace new ${BRANCH_NAME}
                  terraform apply -input=false -auto-approve tfplan
                '''
              } else if (params.ACTION == 'destroy') {
                sh '''
                  terraform init -input=false -no-color
                  terraform workspace select ${BRANCH_NAME} || true
                  terraform destroy -auto-approve -input=false
                '''
              }
            }
          }
        }
      }
      post {
        failure {
          script {
            echo "Terraform action failed - notifying and keeping plan artifact for debug."
            // Add Slack/email notifications here (see post pipeline)
          }
        }
      }
    }

    stage('Build & Push Docker Images (parallel)') {
      when { expression { env.BRANCH_NAME != 'main' || (env.BRANCH_NAME == 'main' && params.ACTION == 'apply') } }
      parallel {
        stage('Build Frontend') {
          steps {
            dir('frontend') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                sh '''
                  set -euo pipefail
                  # Build docker image
                  docker build -t ${ECR_REGISTRY}/workshop-frontend:${IMAGE_TAG} .
                  # Login & push
                  aws ecr-public get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY} || true
                  docker push ${ECR_REGISTRY}/workshop-frontend:${IMAGE_TAG}
                '''
                script { stash includes: "**/*", name: "frontend-${IMAGE_TAG}" }
              }
            }
          }
        }
        stage('Build Backend') {
          steps {
            dir('backend') {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
                sh '''
                  set -euo pipefail
                  docker build -t ${ECR_REGISTRY}/workshop-backend:${IMAGE_TAG} .
                  aws ecr-public get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY} || true
                  docker push ${ECR_REGISTRY}/workshop-backend:${IMAGE_TAG}
                '''
                script { stash includes: "**/*", name: "backend-${IMAGE_TAG}" }
              }
            }
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
          sh '''
            set -euo pipefail
            # Update kubeconfig for EKS cluster provisioned by Terraform
            aws eks update-kubeconfig --region ${AWS_REGION} --name $(terraform -chdir=${TF_WORKING_DIR} output -raw eks_cluster_name || echo $CLUSTER_NAME)
            kubectl config set-context --current --namespace ${K8S_NAMESPACE} || kubectl create namespace ${K8S_NAMESPACE} || true

            # Replace image tags in k8s manifests to use the new images (simple sed replace)
            # Make a temp copy of manifests
            TMPDIR=$(mktemp -d)
            cp -r k8s_manifests/* ${TMPDIR}/
            # Update frontend/backend image tags in manifests (adjust to your manifest paths)
            find ${TMPDIR} -type f -name "*.yaml" -print0 | xargs -0 sed -i "s|public.ecr.aws/w8u5e4v2/workshop-frontend:.*|${ECR_REGISTRY}/workshop-frontend:${IMAGE_TAG}|g"
            find ${TMPDIR} -type f -name "*.yaml" -print0 | xargs -0 sed -i "s|public.ecr.aws/w8u5e4v2/workshop-backend:.*|${ECR_REGISTRY}/workshop-backend:${IMAGE_TAG}|g"

            # Apply MongoDB, backend, frontend, LB/Ingress
            kubectl apply -f ${TMPDIR}/mongo_v1 --recursive
            kubectl apply -f ${TMPDIR}/backend-deployment.yaml
            kubectl apply -f ${TMPDIR}/backend-service.yaml
            kubectl apply -f ${TMPDIR}/frontend-deployment.yaml
            kubectl apply -f ${TMPDIR}/frontend-service.yaml
            kubectl apply -f ${TMPDIR}/full_stack_lb.yaml

            # Wait for rollout
            kubectl rollout status deployment/frontend -n ${K8S_NAMESPACE} --timeout=120s || echo "frontend rollout may be slow"
            kubectl rollout status deployment/backend -n ${K8S_NAMESPACE} --timeout=120s || echo "backend rollout may be slow"

            # export deployed image refs for promotion & rollback
            kubectl get deploy frontend -n ${K8S_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}' > frontend_deployed_image.txt || true
            kubectl get deploy backend -n ${K8S_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}' > backend_deployed_image.txt || true
            echo "Deployed frontend image: $(cat frontend_deployed_image.txt)"
          '''
        }
      }
    }

    stage('Optional: Deploy Monitoring') {
      when { expression { params.DEPLOY_MONITORING == true && params.ACTION == 'apply' } }
      steps {
        dir("${TF_WORKING_DIR}") {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
            sh '''
              terraform init -input=false -no-color
              terraform apply -input=false -auto-approve -target=helm_release.prometheus
            '''
          }
        }
      }
    }

  } // stages

  post {
    success {
      script {
        echo "Deployment pipeline completed successfully."
        // Optional: send Slack / email
      }
    }
    failure {
      script {
        echo "Pipeline failed - preserving artifacts for debugging."
        archiveArtifacts artifacts: '**/tfplan.json, **/*deployed_image.txt', allowEmptyArchive: true
        // Optional: Slack notification
      }
    }
    always {
      cleanWs()
    }
  }
}
