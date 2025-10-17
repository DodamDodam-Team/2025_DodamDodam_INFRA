### SetUp
```shell
git clone https://github.com/DodamDodam-Team/2025_DodamDodam_INFRA.git
cd 2025_DodamDodam_INFRA/infra/
terraform init
terraform apply --auto-approve -parallelism=30
```

<br>

### Code Structure
```
├── Infra
│   ├── locals.tf
│   ├── main.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   └── modules
│       ├── alb
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       │
│       ├── auto_scaling_group
│       │   ├── main.tf
│       │   └── variables.tf
│       │
│       ├── ec2
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   ├── provider.tf
│       │   └── variables.tf
│       │
│       ├── ecr
│       │   ├── main.tf
│       │   └── variables.tf
│       │
│       ├── elaticache
│       │   ├── main.tf
│       │   └── variables.tf
│       │
│       ├── launch_template
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   ├── provider.tf
│       │   └── variables.tf
│       │ 
│       ├── rds
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       │
│       ├── secrets-manager
│       │   ├── main.tf
│       │   └── variables.tf
│       │
│       └── vpc
│           ├── locals.tf
│           ├── main.tf
│           ├── outputs.tf
│           └── variables.tf
│
└── Script
    ├── db.sql
    └── Jenkinsfile
``` 