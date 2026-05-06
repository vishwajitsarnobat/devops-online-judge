# After `terraform apply`, these values are printed to the console.
# Jenkins captures ec2_public_ip to generate the Ansible inventory.

output "ec2_public_ip" {
  description = "Public IP of the Online Judge EC2 instance"
  value       = aws_instance.judge_server.public_ip
}

output "ec2_instance_id" {
  description = "Instance ID (useful for debugging in AWS Console)"
  value       = aws_instance.judge_server.id
}
