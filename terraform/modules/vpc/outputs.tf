output "vpc_id" {
  value       = "${aws_vpc.packer.id}"
  description = "VPC ID"
}

output "subnet_id" {
  value       = "${aws_subnet.packer.id}"
  description = "Subnet ID"
}
