# aws-eks-devops-project
End-to-end DevOps project on AWS using Terraform, Jenkins CI/CD, Docker, Kubernetes (EKS), Helm, Nexus, and CloudWatch. Implements infrastructure automation, container orchestration, and multi-environment deployment with monitoring
# AWS EKS DevOps Project

A complete infrastructure-as-code project demonstrating a modern CI/CD pipeline deploying a custom Spring Boot application to AWS Elastic Kubernetes Service (EKS). This project showcases full automation from code commit to production deployment using industry-standard DevOps tools.

## 📋 Project Overview

This project implements a robust DevOps pipeline that:
- **Provisions AWS infrastructure** using Terraform (EKS cluster, networking, Jenkins server)
- **Automates configuration** with Ansible (Jenkins setup, tool installation)
- **Builds and containerizes** a custom Spring Boot application
- **Orchestrates deployments** on Kubernetes with Helm charts
- **Manages artifacts** with Nexus Repository
- **Automates CI/CD** with Jenkins pipelines triggered by GitHub webhooks

## 🏗️ Architecture

![Architecture Diagram](docs/architecture-diagram.png)

**Infrastructure Stack:**
- **Cloud Provider:** AWS
- **Container Orchestration:** Elastic Kubernetes Service (EKS)
- **CI/CD Server:** Jenkins on EC2
- **Artifact Management:** Nexus Repository on EKS
- **Database:** PostgreSQL on Kubernetes

**Tooling Stack:**
- **Infrastructure as Code:** Terraform
- **Configuration Management:** Ansible
- **Containerization:** Docker
- **Orchestration:** Kubernetes
- **Package Management:** Helm
- **Monitoring:** AWS CloudWatch

## 🎯 Application Overview

### **DevOps Status Dashboard**

A Spring Boot application that provides real-time visibility into the CI/CD pipeline that deploys it.

![Dashboard Screenshot](docs/dashboard-screenshot.png)
![API Endpoints](docs/api-screenshot.png)

**Features:**
- Real-time pipeline status monitoring
- Kubernetes cluster health dashboard  
- Deployment history with rollback capability
- System metrics and performance monitoring

## 🚀 Quick Start

### Prerequisites
- AWS Account with appropriate permissions
- Terraform v1.0+
- Ansible v2.9+
- Docker and Docker Compose
- kubectl and awscli

### Deployment Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/aws-eks-devops-project.git
   cd aws-eks-devops-project
2. **Initialize Terraform**

   ```bash
   cd terraform
   terraform init

3. **Deploy Infrastructure (Be cautious of AWS costs)**

   ```bash
   terraform plan
   terraform apply -var="my_ip=$(curl -s ifconfig.me)/32"

4. **Configure Jenkins with Ansible**
   ```bash
   cd ../ansible
   ansible-playbook -i inventory jenkins-setup.yml

5. **Access Jenkins**

- SSH tunnel: ssh -L 8080:localhost:8080 ubuntu@<JENKINS_IP>
- Open: http://localhost:8080
- Get initial password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword

6. **Run the Pipeline**

- Configure Jenkins credentials for AWS and Kubernetes
- Trigger the pipeline via GitHub webhook or manually

## 📁 Repository Structure
aws-eks-devops-project/

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| **application/** | Custom Spring Boot application | |
| ↳ | Application source code | `src/` |
| ↳ | Container definition | `Dockerfile` |
| ↳ | Local development | `docker-compose.yml` |
| **terraform/** | Infrastructure as Code | |
| ↳ | Primary infrastructure | `main.tf` |
| ↳ | Input variables | `variables.tf` |
| ↳ | Output values | `outputs.tf` |
| **ansible/** | Configuration Management | |
| ↳ | Jenkins installation | `jenkins-setup.yml` |
| ↳ | Nexus configuration | `nexus-config.yml` |
| **kubernetes/** | Kubernetes manifests | |
| ↳ | App deployment | `deployment.yml` |
| ↳ | Network services | `service.yml` |
| ↳ | Traffic routing | `ingress.yml` |
| **helm/** | Helm charts | |
| ↳ | Application chart | `app-chart/` |
| ↳ | Database chart | `db-chart/` |
| **jenkins/** | CI/CD pipelines | |
| ↳ | Pipeline definition | `Jenkinsfile` |
| **docs/** | Documentation | |
| ↳ | System diagram | `architecture.png` |
| | Main documentation | `README.md` |

### 🔧 Key Features
## Infrastructure Automation

- VPC Networking: Secure network isolation with public and private subnets
- EKS Cluster: Managed Kubernetes cluster with worker nodes
- Jenkins Server: CI/CD automation server with pre-configured tools
- CloudWatch Monitoring: Resource monitoring and alerting

## CI/CD Pipeline

- Automatic Builds: Triggered on Git pushes via webhooks
- Docker Image Management: Build, version, and push to Nexus
- Kubernetes Deployment: Automated rolling deployments to EKS
- Environment Promotion: Dev → Test deployment workflow
- Self-Service Deployment: Manual promotion with environment selection

## Kubernetes Implementation

- Microservices Architecture: Spring Boot app + PostgreSQL database
- Stateful Database: PostgreSQL with persistent volumes
- Config Management: ConfigMaps and Secrets for configuration
- Ingress Routing: NGINX ingress controller with health checks
- High Availability: Multi-node cluster with pod distribution

## 🛠️ Technologies Used

| Technology | Purpose | Version |
|------------|---------|---------|
| Terraform | Infrastructure Provisioning | 1.5+ |
| AWS EKS | Kubernetes Orchestration | 1.28+ |
| Ansible | Configuration Management | 2.12+ |
| Jenkins | CI/CD Automation | 2.4+ |
| Docker | Containerization | 20.10+ |
| Kubernetes | Container Orchestration | 1.28+ |
| Helm | Package Management | 3.10+ |
| Nexus | Artifact Repository | 3.4+ |
| Spring Boot | Application Framework | 3.1+ |
| PostgreSQL | Database | 13+ |

## 📊 Monitoring & Logging

- **AWS CloudWatch:** Cluster and node monitoring
- **Kubernetes Dashboard:** Pod and deployment status
- **Custom Health Endpoints:** Application health checks
- **Ingress Health Checks:** Automated traffic management

## 🔒 Security Considerations

- **Least Privilege IAM Roles:** Minimal permissions for services
- **Private Subnets:** Worker nodes in isolated network
- **SSL Termination:** HTTPS via ingress controller
- **Secret Management:** Kubernetes secrets for sensitive data
- **Network Policies:** Controlled pod-to-pod communication

## 🚨 Cost Management

**Warning:** This project creates resources that incur AWS costs:
- EKS Cluster: ~$0.10/hour
- EC2 Instances: varies by type
- NAT Gateway: ~$0.045/hour + data processing
- EBS Volumes: varies by size

**Always run `terraform destroy` when finished to avoid unnecessary charges.**

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit a pull request

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by real-world DevOps practices
- Built as a comprehensive learning project
- Thanks to the open-source community for excellent tools and documentation
