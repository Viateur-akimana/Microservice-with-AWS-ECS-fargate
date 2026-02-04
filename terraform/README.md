# Terraform for Microservice with AWS ECS Fargate

[![AWS ECS Fargate](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/fargate/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)](https://www.terraform.io/)
[![Repo](https://img.shields.io/badge/GitHub-Viateur--akimana%2FMicroservice--with--AWS--ECS--fargate-181717?logo=github)](https://github.com/Viateur-akimana/Microservice-with-AWS-ECS-fargate)

Infrastructure as Code for the "Microservice with AWS ECS Fargate" project. This directory contains a modular 3‑tier architecture for deploying the FastAPI microservices on AWS ECS Fargate.

## Architecture Overview

The infrastructure is organized into **3 tiers**:

### 🌐 Tier 1: Presentation Layer (`modules/loadbalancer`)
- **Application Load Balancer**: Internet-facing HTTP/HTTPS endpoint
- **Target Groups**: Health-checked routing to backend services
- **Listener Rules**: Path-based routing (`/users/`, `/orders/`, `/payments/`)

### 💻 Tier 2: Application Layer (`modules/compute`)
- **ECS Fargate Cluster**: Serverless container orchestration
- **ECS Services**: Three microservices (user, order, payment)
- **ECR Repositories**: Container image storage
- **Service Discovery**: AWS Cloud Map for inter-service communication
- **CloudWatch Logs**: Centralized logging

### 🗄️ Tier 3: Data Layer (`modules/data`)
- **RDS PostgreSQL**: Managed relational database
- **ElastiCache Redis**: In-memory caching layer
- **Secrets Manager**: Secure credential storage

### 🔐 Cross-Cutting Concerns
- **Networking** (`modules/networking`): VPC, subnets, routing, NAT
- **Security** (`modules/security`): Security groups, IAM roles and policies

## Module Structure

```
terraform/
├── main.tf                    # Root module orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configuration
├── terraform.tfvars.example   # Example variable values
│
└── modules/
    ├── networking/            # VPC, Subnets, Gateways
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security/              # Security Groups, IAM Roles
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── data/                  # RDS, ElastiCache, Secrets
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── loadbalancer/          # ALB, Target Groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── compute/               # ECS, ECR, Service Discovery
        ├── main.tf
        ├── ecs-services.tf
        ├── variables.tf
        └── outputs.tf
```

## Benefits of Modular Architecture

✅ **Reusability**: Modules can be reused across different environments  
✅ **Maintainability**: Changes are isolated to specific modules  
✅ **Testability**: Modules can be tested independently  
✅ **Scalability**: Easy to add new services or modify existing ones  
✅ **Clear Separation**: Each tier has distinct responsibilities  
✅ **Environment Isolation**: Same modules, different variable files  

## Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Review the Plan

```bash
terraform plan
```

### Deploy Infrastructure

```bash
terraform apply
```

### Destroy Infrastructure

```bash
terraform destroy
```

## Module Dependencies

The modules are orchestrated in the following order:

```
1. networking    → Creates VPC, subnets, routing
2. security      → Creates security groups using VPC ID
3. data          → Creates RDS & Redis in private subnets
4. loadbalancer  → Creates ALB in public subnets
5. compute       → Creates ECS services with all dependencies
```

## Customization

### Using Different Environments

Create environment-specific variable files:

```bash
# terraform.tfvars.dev
environment = "dev"
project_name = "fastapi-ms-dev"

# terraform.tfvars.prod
environment = "prod"
project_name = "fastapi-ms-prod"
```

Deploy with:

```bash
terraform apply -var-file="terraform.tfvars.dev"
```

### Adding a New Service

1. Add the service name to `variables.tf`:
   ```hcl
   services = ["user-service", "order-service", "payment-service", "new-service"]
   ```

2. The infrastructure will automatically create:
   - ECR repository
   - ECS task definition
   - ECS service
   - Target group
   - Listener rule (manual routing rule needed)

### Modifying Resources

Each module can be modified independently:

- **Scale ECS tasks**: Modify `desired_count` in `modules/compute/ecs-services.tf`
- **Change instance types**: Modify RDS/ElastiCache instance classes in `modules/data/main.tf`
- **Adjust networking**: Modify CIDR blocks in `modules/networking/main.tf`

## Best Practices

1. **State Management**: Use remote state (S3 + DynamoDB) for production
2. **Variable Files**: Never commit `terraform.tfvars` with secrets
3. **Module Versioning**: Pin module versions for stability
4. **Tagging**: All resources are tagged with Environment and Tier
5. **Security**: Follow least-privilege IAM principles

## Outputs

Key outputs from the infrastructure:

- `alb_url`: Application Load Balancer URL
- `ecs_cluster_name`: ECS cluster name
- `ecr_repositories`: Map of ECR repository URLs
- `rds_endpoint`: Database endpoint (sensitive)
- `redis_endpoint`: Redis endpoint (sensitive)

Access outputs:

```bash
terraform output
terraform output alb_url
terraform output -json ecr_repositories
```

## Troubleshooting

### Module not found

```bash
terraform init -upgrade
```

### Circular dependencies

Check module dependencies in `main.tf` and ensure proper `depends_on` usage.

### Resource conflicts

Ensure unique naming across environments using the `environment` variable.

## Additional Resources

- [Terraform Module Documentation](https://www.terraform.io/docs/language/modules/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
