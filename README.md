# Terraform Multi-Stage AWS Infrastructure Deployment

This project uses Terraform to deploy a three-tier application infrastructure (WEB-APP, BACKEND, DATABASE) on AWS. The deployment is split into two distinct stages for better management and separation of concerns:

1.  **01-network-infra**: Provisions the core networking components (VPC, Subnet, Internet Gateway, Route Tables, Security Groups, and an Elastic IP for the web server).
2.  **02-compute-infra**: Launches the EC2 instances for each tier into the network created in the first stage, associating them with the appropriate security groups and Elastic IP.

## Project Structure

## Project Structure
terraform-multi-stage/
├── 01-network-infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
├── 02-compute-infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
└── README.md


## Prerequisites

1.  **Terraform Installed:** Ensure you have Terraform v1.0.0 or later installed. ([Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
2.  **AWS Account:** An active AWS account.
3.  **AWS CLI Configured:** The AWS CLI installed and configured with credentials that have sufficient permissions to create the resources defined (VPC, EC2, S3, IAM might be needed depending on provider configuration, EIP, etc.). ([AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
    *   The user/role associated with the credentials should ideally have permissions equivalent to AdministratorAccess for ease of setup, or at least specific permissions for VPC, EC2 (including EIPs and Security Groups), and potentially IAM if creating roles.
4.  **EC2 Key Pair:** An existing EC2 Key Pair in the target AWS region (default: me-central-1). The name of this key pair needs to be specified in the variables.tf file for the 02-compute-infra stage (variable: key_pair_name, default: "UE"). You must have the corresponding .pem private key file to SSH into the instances.
5.  **Your Public IP Address:** You will need to know your current public IP address to configure secure SSH access in the security groups.

## Configuration

Before deploying, you **must** configure important variables.

### Stage 1: 01-network-infra

Navigate to the 01-network-infra directory and review/edit variables.tf:

  **aws_region**: (Default: me-central-1) The AWS region where resources will be created.
  **project_name**: (Default: my-app) A prefix used for naming some resources like the VPC, subnet, and security group Name tags.
  **availability_zone**: (Default: me-central-1a) Ensure this is a valid AZ in your chosen region.
  **my_ip_cidr**: **CRITICAL!** Change the default 0.0.0.0/0` to your actual public IP address with a /32 suffix (e.g., "YOUR.IP.ADDRESS.HERE/32"`). This secures SSH access to the instances. You can find your IP by searching "what is my ip" on Google.
  ***_name_tag variables** (e.g., vpc_name_tag, public_subnet_name_tag, web_app_sg_name_tag, etc.): These define the Name tags that will be applied to the network resources. The 02-compute-infra script will use these exact tag values to look up the resources. Ensure they are sufficiently unique if you have other resources in your account.

### Stage 2: 02-compute-infra

Navigate to the 02-compute-infra directory and review/edit variables.tf:

  **aws_region**: (Default: me-central-1) Should match the region used in Stage 1.
  ***_name_tag_to_lookup variables** (e.g., vpc_name_tag_to_lookup, public_subnet_name_tag_to_lookup, etc.): These **must exactly match** the Name tag values defined and applied by the 01-network-infra script. The defaults are set to match the defaults in Stage 1.
  **key_pair_name**: (Default: "UE") The name of your existing EC2 Key Pair in the target region.
  **ami_id**: (Default: Amazon Linux 2 AMI for me-central-1) The AMI ID for launching EC2 instances.
  **Instance Types**: Review web_app_instance_type, backend_instance_type, db_instance_type.

## Deployment Steps

**Important:** Deploy Stage 1 before Stage 2.

### Stage 1: Deploy Network Infrastructure

1.  **Navigate to the network directory:**
    
bash
    cd 01-network-infra
    
2.  **Initialize Terraform:**
    
bash
    terraform init
    
3.  **Review the plan:**
    
bash
    terraform plan
    
    This will show you the VPC, Subnet, IGW, Route Table, Security Groups, and Elastic IP that will be created.
4.  **Apply the configuration:**
    
bash
    terraform apply
    
    Type yes when prompted. Note the outputs, especially the Name tag values, as these are used by the next stage.

### Stage 2: Deploy Compute Infrastructure

1.  **Navigate to the compute directory:**
    
bash
    cd ../02-compute-infra 
    
    (Assuming you are in the 01-network-infra directory)
2.  **Initialize Terraform:**
    
bash
    terraform init
    
3.  **Review the plan:**
    
bash
    terraform plan
    
    Terraform will use data sources to find the network resources created in Stage 1 based on their Name tags. If successful, it will show the EC2 instances to be created. If the network resources are not found, this step will fail.
4.  **Apply the configuration:**
    
bash
    terraform apply
    
    Type yes when prompted. This will launch the WEB-APP, BACKEND, and DATABASE instances.

## Accessing Instances

  **WEB-APP:** Can be accessed via its Elastic IP address (outputted as web_app_elastic_ip_address).
  **BACKEND & DATABASE:** Will have public IPs (outputted as backend_public_ip and database_public_ip).
  **SSH Access:** Use the .pem file corresponding to the key_pair_name specified. The default username for the Amazon Linux 2 AMI is ec2-user.
    
bash
    ssh -i /path/to/your/private-key.pem ec2-user@<INSTANCE_PUBLIC_IP>
    

**Security Note for Database:** The DATABASE instance is configured to receive a public IP and its security group (db_sg) allows SSH from my_ip_cidr and database port access from the backend_sg. Exposing a database directly with a public IP is generally **not recommended** for production. Consider using private subnets and a bastion host or VPN for database access. The rule for direct DB access from my_ip_cidr is commented out by default in 01-network-infra/main.tf but can be enabled for temporary administrative access with extreme caution.

## Destroying Infrastructure

To remove all created resources, destroy them in the reverse order of creation:

1.  **Destroy Compute Infrastructure:**
    
bash
    cd 02-compute-infra
    terraform destroy
    
2.  **Destroy Network Infrastructure:**
    
bash
    cd ../01-network-infra
    terraform destroy
    
    Always confirm the resources to be destroyed before typing yes.

## Outputs

Each stage will produce outputs that provide information about the created resources, such as IDs and IP addresses. The 01-network-infra outputs also include the Name tag values used for lookup.