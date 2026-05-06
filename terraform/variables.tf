variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1" # Mumbai
}

variable "instance_type" {
  description = "EC2 instance size (t3.micro = free tier)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 Key Pair (created in AWS Console or via CLI)"
  type        = string
  default     = "online-judge-key"
}

# Ubuntu 22.04 LTS AMI for ap-south-1 (Mumbai).
# Find the latest at: https://cloud-images.ubuntu.com/locator/ec2/
# or run:  aws ec2 describe-images --owners 099720109477 \
#            --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
#            --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text --region ap-south-1
variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID for ap-south-1"
  type        = string
  default     = "ami-0dee22c13ea7a9a67"
}

variable "docker_user" {
  description = "Docker Hub username for pulling images"
  type        = string
  default     = "vishwajitsarnobat"
}
