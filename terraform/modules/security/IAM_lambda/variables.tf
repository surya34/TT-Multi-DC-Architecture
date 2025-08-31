variable "role_name" { 
 type = string 
}

variable "permissions_boundary_arn" { 
 type = string
 default = null 
}

variable "tags" { 
 type = map(string)
 default = {} 
}
