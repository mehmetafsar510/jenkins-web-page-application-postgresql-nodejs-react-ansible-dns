output "nodejs-ip" {
  value       =  module.compute.nodejs-ip #{ for i in module.compute.nodejs-ip : i.tags.Name => "${i.public_ip}" }
  sensitive   = false
  description = "public ip of the nodejs"
}

output "react-ip" {
  value       = { for i in module.compute.react-ip : i.tags.Name => "${i.public_ip}" }
  sensitive   = false
  description = "public ip of the react"
}


output "postgress-ip" {
  value       = module.compute.postgress-ip
  sensitive   = false
  description = "public ip of the postgress"
}