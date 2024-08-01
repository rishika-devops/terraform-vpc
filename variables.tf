variable "cidr_block" {
    type = string
    default = "10.0.0.0/16"
}
variable "enable_dns_hostnames" {
    default  = true
}
variable "vpc_tags" {
    type = map
    default = {
    Name = "roboshop"
    environment = "dev"
    }
}
variable "common_tags" {
    default = {}
}
variable "project_name" {
    default = "roboshop"
}
variable "environment" {
    default = "dev"
}
variable "igw_tags" {
    default = {}
}
variable "public_subnets_cidr" {
    type = list
    validation {
        condition = length(var.public_subnets_cidr) == 2
        error_message = "please give 2 public subnet cidr"
    }
}
variable "public_subnets_tags"{
    default = {}
}
variable "private_subnets_cidr" {
    type = list
    validation {
        condition = length(var.private_subnets_cidr) == 2
        error_message = "please give 2 private subnet cidr"
    }
}
variable "private_subnets_tags"{
    default = {}
}
variable "database_subnets_cidr" {
    type = list
    validation {
        condition = length(var.database_subnets_cidr) == 2
        error_message = "please give 2 database subnet cidr"
    }
}
variable "database_subnets_tags"{
    default = {}
}
variable "nat_gateway_tags" {
    default = {}
}
variable "public_route_table_tags" {
    default = {}
}
variable "private_route_table_tags"{
    default = {}
}
variable "database_route_table_tags" {
    default = {}
}
variable "is_peering_required" {
    default = false
    type = bool
}
variable "acceptor_vpc_id" {
    default = ""
    type = string
}
variable "vpc_peering_tags" {
    default = {}
}