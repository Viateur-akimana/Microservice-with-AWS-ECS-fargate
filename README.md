# Microservice with AWS ECS Fargate

[![Repo](https://img.shields.io/badge/GitHub-Viateur--akimana%2FMicroservice--with--AWS--ECS--fargate-181717?logo=github)](https://github.com/Viateur-akimana/Microservice-with-AWS-ECS-fargate)
[![AWS ECS Fargate](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/fargate/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)](https://www.terraform.io/)

Concise, production‑focused guide for running and deploying the "Microservice with AWS ECS Fargate" project. This implementation includes three FastAPI services (user, order, payment) and Terraform IaC for AWS (ECS Fargate, ALB, RDS, Redis). Source repo: https://github.com/Viateur-akimana/Microservice-with-AWS-ECS-fargate

- Services:
  - services/user-service
  - services/order-service
  - services/payment-service
- IaC: terraform/ (modular VPC, ALB, ECS, RDS, Redis, IAM)

## Architecture
- Entry: AWS Application Load Balancer (path routing)
- Compute: ECS Fargate services pulling images from Amazon ECR
- Data: Amazon RDS for PostgreSQL, Amazon ElastiCache (Redis)
- Observability: CloudWatch Logs; Prometheus `/metrics` exposed by each service
- Security: IAM task roles, Security Groups, Secrets (via env/Secrets Manager)

## Production Deployment on AWS (Terraform + ECS Fargate)
Prereqs:
- AWS account and credentials configured (`aws configure`)
- Terraform ≥ 1.5, AWS CLI ≥ 2.0, Docker

High‑level flow:
1) Create ECR repos and push images
2) Configure Terraform variables
3) `terraform apply` to provision VPC, ALB, RDS, Redis, ECS, Services
4) Access services via ALB DNS output

### 1) Build and Push Images to ECR
```
AWS_REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
for SVC in user-service order-service payment-service; do
  REPO_NAME=$SVC
  aws ecr describe-repositories --repository-names $REPO_NAME >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name $REPO_NAME >/dev/null
  docker build -t $REPO_NAME:latest services/$SVC
  docker tag $REPO_NAME:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
  aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
  docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
done
```

### 2) Configure Terraform
```
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (region, CIDRs, DB sizes, ECR image URIs, etc.)
```
See `terraform/README.md` for module details and variables.

### 3) Deploy
```
terraform init
terraform plan
terraform apply
```
Key outputs (examples):
- `alb_dns_name` — public ALB URL
- `service_discovery_namespace` — internal discovery domain

### 4) Verify
- Health: `curl http://<alb_dns_name>/users/health` (also `/orders/health`, `/payments/health`)
- Docs: `http://<alb_dns_name>/users/docs`
- Metrics: `http://<alb_dns_name>/users/metrics` (if exposed via rules)

## Configuration & Environment
Each service uses Pydantic Settings with `.env` support. Common variables:
- `DATABASE_URL` — Postgres connection string
- `REDIS_URL` — Redis connection string
- `JWT_SECRET`, `JWT_ALGORITHM`, `JWT_EXPIRATION_HOURS`
- `LOG_LEVEL`

Production recommendations:
- Store secrets in AWS Secrets Manager or SSM Parameter Store; inject into ECS task env via Terraform
- Separate DBs per service and least‑privilege users
- Restrict Security Groups to ALB ingress and required egress only

## Operations
- Logs: CloudWatch Logs per ECS task (awslogs driver)
- Health checks: `/health` endpoints for ALB target groups
- Metrics: `/metrics` Prometheus format
- Scaling: Tune desired counts/autoscaling in Terraform (compute module)
- Zero‑downtime: Rolling updates in ECS with target group health checks

## CI/CD (Suggested)
- Build & tag images on each commit (e.g., `:sha-<gitsha>`, `:staging`, `:prod`)
- Push to ECR, then run `terraform plan`/`apply` via pipeline with approvals
- Manage per‑env via separate workspaces or `tfvars` files

## Repository Layout
- `services/<service-name>` — FastAPI apps with Dockerfiles
- `terraform/` — Modular IaC for AWS (networking, security, data, load balancer, compute)

For detailed Terraform module breakdown, see `terraform/README.md`.
