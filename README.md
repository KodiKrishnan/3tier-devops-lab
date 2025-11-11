# ⚙️ 3tier-devops-lab

[![Build Status](https://img.shields.io/badge/Jenkins-Pipeline-blue?logo=jenkins)](#)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?logo=terraform)](#)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange?logo=amazon-aws)](#)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-blue?logo=grafana)](#)

> **A complete 3-Tier Cloud DevOps Lab** — Terraform · Jenkins · Docker · AWS EKS · Prometheus · Grafana

`3tier-devops-lab` is an **end-to-end DevOps automation project** that provisions AWS infrastructure using **Terraform**, deploys a full **3-tier web application (MongoDB · Node.js · React)** on **EKS**, and automates CI/CD via **Jenkins pipelines** — with integrated observability and cost optimization.

---

## 🧭 Overview

This lab simulates a real-world DevOps pipeline — from **Infrastructure as Code** to **automated CI/CD**, with **container orchestration, monitoring, and intelligent resource management** on AWS.

---

## 🏗️ Architecture

```
GitHub Repo
│
└──► Jenkins Pipeline (CI/CD)
    │
    ├──► Terraform → AWS EKS + VPC + IAM
    │
    ├──► Docker Build (Frontend / Backend)
    │
    ├──► Kubernetes Deployment (3-Tier App)
    │
    └──► Monitoring Stack (Prometheus + Grafana)
```

---

## 🧰 Tech Stack

| Layer         | Tools                                      |
|--------------|---------------------------------------------|
| **IaC**       | Terraform + Helm provider                  |
| **Cloud**     | AWS (EKS, EC2, VPC, IAM, ECR, Route53)     |
| **CI/CD**     | Jenkins (Declarative Pipeline)             |
| **Containers**| Docker                                     |
| **App Stack** | MongoDB · Node.js · React                  |
| **Monitoring**| Prometheus · Grafana                       |
| **Security**  | tfsec · npm audit · Terraform validate     |

---

## 🚀 Key Features

- 🧱 Infrastructure as Code using Terraform modules  
- 🔁 Immutable container builds (Git SHA-based tags)  
- ⚙️ Automated EKS provisioning (spot + on-demand nodes)  
- 🧩 Parallel Docker builds (frontend + backend)  
- 🛡️ Security scans (`tfsec`, `npm audit`)  
- 🧠 Approval-gated Terraform Apply on `main`  
- 📊 Full observability (Grafana dashboards via Helm)  
- 💸 Cost optimization (cluster-autoscaler, spot instances)  
- 🔄 Rollback hooks and cleanup automation  

---

## 📂 Repository Structure

```
3tier-devops-lab/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── values.yaml
├── k8s_manifests/
│   ├── mongo/
│   ├── backend/
│   ├── frontend/
│   └── full_stack_lb.yaml
├── Jenkinsfile
├── eks-destroy.sh
└── README.md
```

---

## ⚙️ Jenkins Pipeline Summary

| Stage                   | Purpose                                      |
|------------------------|----------------------------------------------|
| **Static Checks**       | Terraform fmt/validate, tfsec, npm audit     |
| **Terraform Plan**      | Generate & archive infra plan                |
| **Approval Gate**       | Human approval before apply (main branch)    |
| **Terraform Apply/Destroy** | Provision or destroy infra              |
| **Parallel Build**      | Docker builds for frontend/backend           |
| **Deploy to EKS**       | Apply manifests (Mongo, API, UI, Ingress)    |
| **Deploy Monitoring**   | Helm install Prometheus + Grafana            |
| **Cleanup**             | Post-run cleanup, artifact archive, notify   |

---

## 🔐 Jenkins Setup

| Requirement     | Details                                           |
|-----------------|---------------------------------------------------|
| **Agent tools** | Docker, Terraform, kubectl, awscli                |
| **Credentials** | `aws-creds`, `ecr-docker-creds`                   |
| **Permissions** | IAM user with EKS, EC2, S3, ECR, Route53 access   |
| **Terraform backend** | S3 bucket + optional DynamoDB locking       |

---

## 🧠 DevOps Strategies Applied

- ✅ Two-phase Terraform (plan → approval → apply)  
- ✅ Workspaces per branch for isolated environments  
- ✅ Immutable Docker images tagged by Git SHA  
- ✅ Parallel Jenkins stages for speed  
- ✅ Integrated scanning & validation  
- ✅ Cost-efficient infra (spot/on-demand blend)  
- ✅ End-to-end observability (Grafana dashboards 1860, 315, 6417, 179)  

---

## 📊 Monitoring Access

```bash
kubectl get svc -n prometheus prometheus-grafana
```

Then open:

```
http://<EXTERNAL-IP>:3000
```

Login credentials:

```
Username: admin
Password: prom-operator
```

---

## 🧹 Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```

Or use:

```bash
./eks-destroy.sh
```

---

## 🏁 Quick Start

```bash
git clone https://github.com/KodiKrishnan/3tier-devops-lab.git
cd 3tier-devops-lab

# Provision Infra
cd terraform
terraform init && terraform apply -auto-approve

# Deploy App
kubectl apply -f k8s_manifests/

# Check LoadBalancer
kubectl get ingress -n workshop

# Cleanup
terraform destroy -auto-approve
```

---

## ✨ Author

**Kodi Arasan**  
☁️ AWS DevOps Engineer | Cloud Architect | Automation Specialist  
🔗 Connect with me on LinkedIn](https://www.linkedin.com/in/kodii2307/)  
💬 “Automating the cloud, one pipeline at a time.”

---

### 🌟 Support

If you like this project, give it a ⭐ on GitHub — it helps others discover open DevOps learning labs!
