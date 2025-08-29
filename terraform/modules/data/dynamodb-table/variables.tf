variable "name" { 
 type = string 

}

variable "hash_key" { 
 type = string  
 default = "id" 
}

variable "ttl_attribute" { 
 type = string  
 default = null 
}

variable "tags" { 
 type = map(string) 
 default = {} 
}


