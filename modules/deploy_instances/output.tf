output "master_ip" {
  value = aws_eip.eip_master.public_ip//"16.170.31.179"
}

output "workers_ip" {
  value = aws_eip.eip_workers[*].public_ip
}

output "key_name" {
  value = aws_key_pair.generated_key.key_name
}

output "path_key_file" {
  value = local_file.local_key_pair.filename
}

output "user_from_ami" {
  value = data.aws_ami.ami_latest.name
}

output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}