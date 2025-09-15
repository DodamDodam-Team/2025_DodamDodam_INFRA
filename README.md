### SetUp
```shell
terraform init
terraform apply --auto-approve
```

<br>

### Code Structure
```
├── locals.tf
├── main.tf
├── provider.tf
├── terraform.tfvars
├── variables.tf
└── modules
    ├── ec2
    │   ├── main.tf
    │   ├── provider.tf
    │   └── variables.tf
    │
    ├── ecr
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    │
    ├── iam
    │   ├── main.tf
    │   ├── provider.tf
    │   └── variables.tf
    │
    ├── rds
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    │
    ├── secrets-manager
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    │
    └── vpc
        ├── main.tf
        ├── outputs.tf
        ├── provider.tf
        └── variables.tf
``` 