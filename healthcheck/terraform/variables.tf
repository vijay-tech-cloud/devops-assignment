variable "region"        { type = string }
variable "cidr" {
    type = string
    default = ""
}
variable "cluster_name"  { 
    type = string 
    default = "trade-eks" 
 }
variable "vpc_id"             {
     type = string      
     default = null 
     }
variable "public_subnet_ids"  { 
    type = list(string) 
    default = ["10.20.0.0/20", "10.20.16.0/20"] 
    }
variable "private_subnet_ids" { 
    type = list(string) 
    default = ["10.20.128.0/20", "10.20.144.0/20"] 
    }
variable "alert_email"{ type = string}
variable "min_size"     { 
    type = number 
    default = 1 
    }
variable "max_size"     { 
    type = number 
    default = 3 
    }
variable "desired_size" { 
    type = number 
    default = 1
     }
variable "ami_type"     { 
    type = string 
    default = "AL2_x86_64"
     } 

variable "create_vpc"   { 
    type = bool   
    default = true 
    }
variable "create_redis" { 
    type = bool   
    default = false 
    }  
variable "owner"        { 
    type = string 
    default = "platform" 
    }
variable "tags"         { 
    type = map(string) 
    default = {} 
    }
