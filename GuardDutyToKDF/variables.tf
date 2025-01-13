variable "hec_url" {
    type = string
    description = "Full URL with port of the HEC"
}

variable "hec_token" {
    type = string
    description = "Token of HEC"
}

variable "org" {
  type = string
  description = "Org name used as prefix for s3 bucket"
}

# variable "aws_profile" {
#   type = string
#   default = "default"
#   description = "AWS CLI profile name"
# }

# variable "region" {
#   type = string
#   description = "Region to put resources in"
#   default = "us-east-1"
# }   

variable "source_service" {
  type = string
  default = "guard-duty"
}

variable "dest_service" {
  type = string
  default = "events"
}