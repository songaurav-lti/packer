output "loki_ip" {
  value       = aws_instance.loki.public_ip
  description = "Public IP address for the Loki and Grafana instance."
}
output "nginx_east_ip" {
  value = aws_instance.nginx_east.public_ip
  description = "Public IP address for the Nginx instance in us-east-2."
}

output "nginx_west_ip" {
  value = aws_instance.nginx_west.public_ip
  description = "Public IP address for the Nginx instance in us-west-2."
}