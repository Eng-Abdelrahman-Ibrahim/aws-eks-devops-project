# AWS EKS DevOps Project

End-to-end DevOps project on AWS using Terraform, Jenkins CI/CD, Docker, Kubernetes (EKS), Helm, Nexus, and CloudWatch. Implements infrastructure automation, container orchestration, and multi-environment deployment with monitoring.

## 📋 Project Overview

This project implements a robust DevOps pipeline that:

- Provisions AWS infrastructure using Terraform (EKS cluster, EC2 instances, networking)
- Automates configuration with Ansible (Jenkins, EKS access, Helm deployments)
- Builds and containerizes a Spring Boot application with React frontend
- Orchestrates deployments on Kubernetes with Helm charts
- Manages Docker artifacts with Nexus Repository
- Automates CI/CD with Jenkins pipelines triggered by GitHub webhooks
- Supports multiple environments (dev, test, prod)
- Monitors infrastructure with CloudWatch alarms and custom dashboards

## 🏗️ Architecture

![Architecture Diagram](docs/architecture.png)
![AWS Diagram](docs/AWS.png)

### Infrastructure Stack

- **Cloud Provider**: AWS
- **Container Orchestration**: Elastic Kubernetes Service (EKS)
- **CI/CD Server**: Jenkins on EC2
- **Configuration Server**: Ansible Control Machine on EC2
- **Artifact Management**: Nexus Repository on EKS
- **Database**: PostgreSQL StatefulSet on Kubernetes
- **Ingress Controller**: NGINX Ingress Controller
- **Monitoring**: AWS CloudWatch with Alarms and Custom Dashboards

### Tooling Stack

- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **Containerization**: Docker
- **Orchestration**: Kubernetes (EKS)
- **Package Management**: Helm 3
- **Monitoring**: AWS CloudWatch, SNS
- **Version Control**: GitHub with Webhooks

## 🎯 Application Overview

### DevOps Deployment Dashboard

A simple Spring Boot + React application that tracks deployment status.

**What it does**:
- Displays deployment records in a web dashboard
- Receives HTTP POST requests from Jenkins pipeline with deployment information
- Stores deployment history in PostgreSQL
- Shows which environment was deployed and whether it succeeded or failed

![Web App](docs/app.png)

**Tech Stack**:
- Backend: Spring Boot 3.x, Java 17, PostgreSQL
- Frontend: React, Node.js, Nginx
- Build: Maven (backend), npm (frontend)

**Note**: The primary focus of this project is the DevOps pipeline itself - infrastructure automation, CI/CD, containerization, and Kubernetes orchestration. The application serves as a practical example to demonstrate these DevOps concepts.

## 📁 Repository Structure

```
aws-eks-devops-project/
│
├── ansible/                          # Configuration management
│   ├── ansible.cfg                   # Ansible configuration
│   ├── inventory                     # Dynamic inventory file
│   ├── site.yml                      # Main playbook orchestrator
│   ├── playbooks/                    # Individual playbooks
│   │   ├── deploy-helm.yml          # Helm chart deployments
│   │   ├── eks-access.yml           # EKS cluster access setup
│   │   ├── install-controller.yml   # Ingress controller installation
│   │   ├── install-jenkins-plugins.yml  # Jenkins plugins automation
│   │   └── install-jenkins.yml      # Jenkins installation
│   ├── roles/                        # Ansible roles
│   │   ├── common/                  # Common tasks
│   │   ├── eks-access/              # EKS authentication
│   │   ├── helm/                    # Helm operations
│   │   └── jenkins/                 # Jenkins configuration
│   └── vars/                         # Variables and secrets
│       ├── main.yml
│       └── secrets.yml              # Encrypted sensitive data
│
├── application/                      # Spring Boot + React application
│   ├── src/main/java/               # Spring Boot backend
│   ├── frontend/                     # React frontend
│   │   ├── src/
│   │   ├── public/
│   │   └── package.json
│   ├── Dockerfile                    # Backend container
│   ├── docker-compose.yaml          # Local development setup
│   ├── pom.xml                      # Maven configuration
│   └── tests/                       # API tests
│       └── test_api_dashboard.py
│
├── EKS/terraform/                    # EKS infrastructure
│   ├── main.tf                      # Main Terraform configuration
│   ├── eks.tf                       # EKS cluster definition
│   ├── kubernetes.tf                # Kubernetes provider setup
│   ├── nexus.tf                     # Nexus deployment
│   ├── nginx-ingress.tf             # Ingress controller
│   ├── security_groups.tf           # Network security
│   ├── roles.tf                     # IAM roles and policies
│   ├── kubeconfig.tf                # Kubeconfig generation
│   ├── ansible-vars.tf              # Ansible variable generation
│   ├── cloudwatch_alarms.tf         # CloudWatch alarms for EKS
│   ├── variables.tf                 # Input variables
│   ├── outputs.tf                   # Output values
│   └── templates/                   # Template files
│       ├── ansible-vars.yml.tpl
│       └── kubeconfig.yml.j2
│
├── helm/                             # Helm charts
│   ├── app-chart/                   # Application chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml              # Default values
│   │   ├── values-dev.yaml.j2       # Dev environment values
│   │   ├── values-test.yaml.j2      # Test environment values
│   │   ├── values-prod.yaml.j2      # Prod environment values
│   │   └── templates/               # Kubernetes manifests
│   │       ├── backend-deployment.yaml
│   │       ├── backend-service.yaml
│   │       ├── frontend-deployment.yaml
│   │       ├── frontend-service.yaml
│   │       ├── app-configmap.yaml
│   │       ├── app-secrets.yaml
│   │       └── app-ingress.yaml
│   └── postgres-chart/              # PostgreSQL chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml.j2
│       ├── values-test.yaml.j2
│       ├── values-prod.yaml.j2
│       └── templates/
│           ├── postgres-statefulset.yaml
│           ├── postgres-service.yaml
│           └── postgres-configmap.yaml
│
├── Jenkins/                          # Jenkins configuration
│   ├── Jenkinsfile                  # Pipeline definition
│   └── Dockerfile                   # Custom Jenkins image
│
├── terraform/servers-setup/         # Initial EC2 setup
│   ├── main.tf                      # Jenkins & Ansible servers
│   ├── outputs.tf                   # Server IP outputs
│   ├── cloudwatch.tf                # CloudWatch alarms for servers
│   └── terraform.tfvars             # Variable values
│
└── scripts/                          # Automation scripts
    ├── manage_infrastructure.sh     # Infrastructure management
    └── cleanup.sh                   # Resource cleanup
```

## 🚀 Complete Setup Guide

### Prerequisites

- **AWS Account** with appropriate permissions
- **AWS CLI** configured with credentials
- **SSH Key**: Create an SSH key pair named `deployer-one` and ensure it exists at `~/.ssh/deployer-one`
  ```bash
  # Generate SSH key if not exists
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/deployer-one -N ""
  chmod 400 ~/.ssh/deployer-one
  ```
- **Terraform** v1.5+
- **Ansible** v2.12+
- **Docker** and Docker Compose
- **kubectl** v1.28+
- **Helm** v3.10+
- **Git** with SSH key configured for GitHub

### Step 1: Deploy Complete Infrastructure

Run the infrastructure management script to provision all resources (EC2 instances, EKS cluster, Nexus, Ingress):

```bash
cd scripts
./manage_infrastructure.sh
# Select "Apply All" option
```

This script provisions:
- Jenkins and Ansible EC2 instances
- Bastion host for secure access
- VPC, subnets, and security groups
- EKS cluster with managed node groups
- Nexus Repository on Kubernetes
- NGINX Ingress Controller with Network Load Balancer
- CloudWatch alarms with SNS email notifications
- Custom CloudWatch dashboards
- SNS topics for alert notifications
- IAM roles and policies
- Generates Ansible inventory and kubeconfig

**Note the output IPs and DNS names** - you'll need them for subsequent steps.

![Console EKS](docs/myapp-eks.png)

![Console EC2](docs/ec2.png)

### Step 2: Configure Local DNS Resolution

Add the Network Load Balancer address to your local hosts file for accessing services via custom domains.

**Linux/Mac**:
```bash
# Get the NLB DNS name from Terraform output
cd EKS/terraform
export NLB_DNS=$(terraform output -raw ingress_nlb_dns)
export NLB_IP=$(dig +short $NLB_DNS | head -n1)

# Add to /etc/hosts
sudo bash -c "cat >> /etc/hosts << EOF
$NLB_IP app-dev.local
$NLB_IP nexus.local
$NLB_IP app-test.local
$NLB_IP app-prod.local
EOF"
```

**Windows**:
```powershell
# Get the NLB IP (use nslookup on the DNS name from Terraform output)
# Edit C:\Windows\System32\drivers\etc\hosts
# Add these lines:
<NLB_IP> app-dev.local
<NLB_IP> nexus.local
<NLB_IP> app-test.local
<NLB_IP> app-prod.local
```

### Step 3: Initial Jenkins Setup

**Access Jenkins** via SSH tunnel or directly through its public IP:

```bash
# Open browser: http://<jenkins-public-ip>:8080
```

**Get Initial Admin Password**:

```bash

# SSH to Jenkins server via bastion
ssh -tt -i ~/.ssh/deployer-one \
  -o ProxyCommand="ssh -i ~/.ssh/deployer-one -W %h:%p ec2-user@<bastion-public-ip>" \
  ec2-user@<jenkins-private-ip> "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"

# Or via Ansible Server directly (After you access Ansible)
ssh jenkins_public_IP
```

**Complete Initial Setup**:
1. Enter the initial admin password
2. Create your admin username and password
3. Install suggested plugins
4. Complete the setup wizard

### Step 4: Install Additional Jenkins Plugins via Ansible

SSH into the Ansible control machine and run the plugin installation playbook:

```bash
# SSH to Ansible server via bastion
cd terraform/servers-setup
terraform output
# Copy and use the ssh_ansible_via_bastion command from output

# Example:
ssh -tt -i ~/.ssh/deployer-one \
  -o StrictHostKeyChecking=no \
  -o ProxyCommand="ssh -i ~/.ssh/deployer-one -W %h:%p ec2-user@<bastion-public-ip>" \
  ec2-user@<ansible-private-ip>

# Navigate to ansible directory
cd ansible

# Run Jenkins plugins installation playbook
ansible-playbook -i inventory playbooks/install-jenkins-plugins.yml
```

This installs additional plugins needed for the pipeline: plugins can be found in ansible/var/main.yml

### Step 5: Configure Jenkins Tools and Credentials

Access Jenkins at `http://<jenkins-public-ip>:8080`

**Configure Global Tools** (Manage Jenkins → Global Tool Configuration):

1. **Maven**:
   - Click "Add Maven"
   - Name: `Maven`
   - Check "Install automatically"
   - Version: Choose latest 3.x version

2. **NodeJS**:
   - Click "Add NodeJS"
   - Name: `NodeJS`
   - Version: 18.x or later
   - Check "Install automatically"

**Add Credentials** (Manage Jenkins → Credentials → System → Global credentials):

1. **GitHub Credentials**:
   - Kind: SSH Username with private key (or Personal Access Token)
   - ID: `github-credentials`
   - Add your GitHub SSH private key or token

2. **AWS Credentials**:
   - Kind: AWS Credentials
   - ID: `aws-credentials`
   - Access Key ID: Your AWS access key
   - Secret Access Key: Your AWS secret key

3. **Docker Registry (Nexus)**:
   - Kind: Username with password
   - ID: `nexus-credentials`
   - Username: `admin` (or your Nexus username)
   - Password: Your Nexus password

4. **Kubernetes Config**:
   - Kind: Secret file
   - ID: `kubeconfig`
   - File: Upload the kubeconfig file from `EKS/terraform/kubeconfig.yaml`

### Step 6: Configure Nexus Repository

Access Nexus at `http://nexus.local`

**Initial Setup**:

1. **Get Admin Password**:
   ```bash
   kubectl get pods -n eks-build | grep nexus
   kubectl logs -n eks-build <nexus-pod-name> | grep password
   ```

2. Sign in with username `admin` and the password from the logs

3. Complete the setup wizard and change the admin password

**Configure Docker Repository**:

1. Navigate to **Server administration** (gear icon) → **Security** → **Realms**

2. **Enable Docker Bearer Token Realm**:
   - Move "Docker Bearer Token Realm" from Available to Active
   - Click Save

3. **Create Docker Hosted Repository**:
   - Go to **Repository** → **Repositories** → **Create repository**
   - Select **docker (hosted)**
   - Configuration:
     - **Name**: `docker-hosted`
     - **HTTP**: Check "Enable" and set port to `8082`
     - **Allow anonymous docker pull**: Check if desired
     - **Deployment policy**: Allow redeploy
   - Click **Create repository**

4. **Verify Connectivity**:
   ```bash
   docker login nexus.local:8082
   # Enter your Nexus credentials
   ```

   ![Nexus](docs/nexus.png)

### Step 7: Configure GitHub Webhook

1. Go to your GitHub repository → **Settings** → **Webhooks** → **Add webhook**
2. Configure:
   - **Payload URL**: `http://<jenkins-public-ip>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Just the push event
   - **Active**: Check
3. Click **Add webhook**

### Step 8: Create and Run Jenkins Pipeline

1. In Jenkins, create a new Pipeline job:
   - **New Item** → **Pipeline**
   - Name: `devops-dashboard-pipeline`

2. Configure the pipeline:
   - **Build Triggers**: Check "GitHub hook trigger for GITScm polling"
   - **Pipeline**:
     - Definition: "Pipeline script from SCM"
     - SCM: Git
     - Repository URL: Your GitHub repo URL
     - Credentials: Select your GitHub credentials
     - Branch: `*/main`
     - Script Path: `Jenkins/Jenkinsfile`

3. **Pipeline Parameters** (defined in Jenkinsfile):
   - `ENVIRONMENT`: Choice parameter (dev, test, prod)

4. **Run the Pipeline**:
   - Click "Build with Parameters"
   - Select environment (dev, test, or prod)
   - The main difference between environments is the image tag and dashboard URL
   - Subsequent commits will trigger automatic builds via webhook

![Jenkins Pipeline](docs/jenkins.png)

### Step 9: Verify Deployment

1. **Check Kubernetes Pods**:
   ```bash
   kubectl get pods -n app-dev
   kubectl get pods -n app-test
   kubectl get pods -n app-prod
   ```

2. **Access Applications**:
   - Dev: http://app-dev.local
   - Test: http://app-test.local
   - Prod: http://app-prod.local
   - Nexus: http://nexus.local

3. **Check Ingress and Services**:
   ```bash
   kubectl get ingress -A
   kubectl get svc -A
   ```
   ![Verify Deployment](docs/kubectl.png)

4. **Monitor CloudWatch**:
   - Go to AWS Console → CloudWatch → Dashboards
   - View "EKS-Nodes-Dashboard" and "Servers-Dashboard"
   - Check Alarms for any triggered alerts

   ![Cloudwatch Dashboard](docs/cloudwatch_dashboards.png)


## 🔧 Key Features

### Multi-Environment Support
- **Dev**: Automatic deployment on every commit
- **Test**: Manual deployment for testing
- **Prod**: Production deployment with same configuration as other environments
- Each environment uses different image tags (build-{BUILD_NUMBER}-dev/test/prod)
- Dashboard URLs are environment-specific

### Infrastructure Automation
- **VPC Networking**: Isolated subnets across multiple AZs
- **EKS Cluster**: Managed Kubernetes with auto-scaling node groups
- **Jenkins Server**: Pre-configured CI/CD automation
- **Ansible Control Machine**: Configuration management
- **Bastion Host**: Secure SSH access to private instances
- **Nexus Repository**: Private Docker registry on Kubernetes
- **CloudWatch Monitoring**: Alarms and custom dashboards for infrastructure health

### Monitoring & Alerting

**CloudWatch Alarms**:
- **EKS Worker Nodes**: High CPU, memory, and disk utilization alerts
- **Ansible Server**: CPU utilization monitoring
- **Jenkins Server**: CPU utilization monitoring
- All alarms trigger SNS notifications when entering ALARM state


**SNS Email Notifications**:
- **Topics Created**:
  - `eks-alerts-topic`: EKS cluster alerts
  - `servers-alerts-topic`: EC2 server alerts
- **Email Notifications**: Automatic email alerts when alarms are triggered
- **Alarm Details**: Includes metric name, threshold, timestamp, and AWS console link


**Custom CloudWatch Dashboards**:
- **EKS-Nodes-Dashboard**: Kubernetes cluster metrics, pod counts, node health
- **Servers-Dashboard**: EC2 instances monitoring (CPU, network I/O, disk read/write)

### CI/CD Pipeline Stages
1. **Checkout SCM**: Pull code from GitHub
2. **Tool Install**: Setup Maven and NodeJS
3. **Select Environment**: Choose deployment target (dev/test/prod)
4. **Clean Workspace**: Prepare build environment
5. **Checkout Code**: Get latest application code
6. **Build Backend Package**: Maven build for Spring Boot
7. **Build Frontend**: React application build with npm
8. **Run Backend Tests**: Execute API tests
9. **Get AWS Info**: Retrieve AWS account details
10. **Docker Login**: Authenticate with Nexus registry
11. **Build and Push Docker Images**: Create and publish containers with environment-specific tags
12. **Deploy with Ansible**: Helm chart deployment to EKS
13. **Post Actions**: Send deployment status to dashboard API

### Kubernetes Implementation
- **Backend Deployment**: Spring Boot application pods
- **Frontend Deployment**: React app served by Nginx
- **PostgreSQL StatefulSet**: Persistent database with PVCs
- **ConfigMaps**: Non-sensitive configuration
- **Secrets**: Encrypted sensitive data
- **Services**: ClusterIP for internal communication
- **Ingress**: HTTP routing with custom domains per environment
- **Health Checks**: Liveness and readiness probes

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
| Spring Boot | Backend Framework | 3.1+ |
| React | Frontend Framework | 18+ |
| PostgreSQL | Database | 13+ |
| NGINX | Ingress Controller | 1.9+ |
| CloudWatch | Monitoring & Alerting | - |
| SNS | Notification Service | - |

## 📊 Monitoring & Observability

### CloudWatch Alarms with Email Notifications

**Alarm Configuration**:
- **HighCPU-Ansible**: Monitors Ansible server CPU utilization
- **HighCPU-Jenkins**: Monitors Jenkins server CPU utilization 
- **EKS-WorkerNodes-HighCPU-EC2**: Monitors EKS worker nodes CPU, Memory, and Disk utilizations

**Example of a high alarm alert using stress**
![Cloudwatch Alarm Diagram](docs/cloudwatch_alarms_test.png)

**SNS Topics for Notifications**:
- **eks-alerts-topic**: Receives EKS cluster alarm notifications
- **servers-alerts-topic**: Receives EC2 server alarm notifications
![SNS topics](docs/SNS_topics.png)

**Email Alerts**:
When an alarm is triggered, you'll receive an email with:
- Alarm name and description
- AWS region and account ID
- Metric details (namespace, name, dimensions)
- Threshold that was breached
- Timestamp of the alarm state change
- Direct link to view the alarm in AWS Console

**Example of a high alarm SNS notification**
![SNS alarm notification](docs/SNS_notification_test.png)


**CloudWatch Dashboards**:
- **EKS-Nodes-Dashboard**: 
  - Kubernetes cluster metrics
  - Pod and node health
  - Resource utilization
- **Servers-Dashboard**: 
  - Jenkins and Ansible server metrics
  - CPU utilization trends
  - Network I/O (bytes in/out)
  - Disk read/write operations

  ![Servers Dashboard](docs/servers-dashboard.png)

### Additional Monitoring

- **Kubernetes**: Pod status and health checks via `kubectl`
- **Application Health Endpoints**: `/actuator/health` for Spring Boot backend
- **Ingress Health Checks**: NGINX performs automated health probes
- **Jenkins Build History**: Track pipeline success/failure rates
- **Nexus Repository**: Monitor Docker image storage and versions

## 🔒 Security Best Practices

- **IAM Roles**: Least privilege access for EKS and services
- **Private Subnets**: Worker nodes and private instances isolated from internet
- **Bastion Host**: Single point of entry for SSH access
- **Security Groups**: Strict ingress/egress rules
- **Kubernetes Secrets**: Encrypted sensitive data
- **Nexus Authentication**: Token-based Docker registry access
- **SSH Key Management**: Centralized SSH key (`deployer-one`)

## 🚨 Cost Management

**Warning**: This project provisions AWS resources (EKS, EC2, NAT Gateway, Load Balancers, etc.) that incur costs.
**For personal use, it is highly recommended to use AWS Free Tier credits when running this project.**

**Always run cleanup when finished**:
```bash
cd scripts
./manage_infrastructure.sh
# Select "Destroy All"

# For thorough cleanup
./cleanup.sh
```

## 🧹 Cleanup

To destroy all resources and avoid charges:

```bash
# From project root
cd scripts
./manage_infrastructure.sh
# Select "Destroy All" option

# This will:
# 1. Destroy EKS cluster and all Kubernetes resources
# 2. Destroy EC2 instances (Jenkins, Ansible, Bastion)
# 3. Destroy networking components (VPC, subnets, NAT Gateway, NLB)
# 4. Remove CloudWatch alarms and dashboards

# For additional cleanup of any orphaned resources
./cleanup.sh
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit a pull request

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built as a learning project to demonstrate DevOps practices
- Focus on infrastructure automation and CI/CD pipelines
- Thanks to the open-source community for excellent tools and documentation

## 📧 Contact

For questions or feedback, please open an issue in the repository.

---

**Note**: This is a demonstration project focused on DevOps practices. The application itself is intentionally simple to keep the focus on infrastructure, automation, and deployment strategies.