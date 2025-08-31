variable "name" { 
 type = string 
}

variable "kms_key_arn" { 
 type = string 
 default = null 
}

variable "dlq_name" { 
 type = string
 default = null 
}

variable "visibility_timeout_secs"  { 
 type = number 
 default = 180 
}

variable "tags" { 
 type = map(string)
 default = {} 
}

# Allow EventBridge to SendMessage (pass specific rule ARNs, or leave empty and we use SourceAccount)
variable "eventbridge_rule_arns" { 
 type = list(string)  
 default = [] 
}

variable "allow_any_eventbridge_in_account" { 
 type = bool
 default = true 
}

variable "fifo_throughput_limit" { 
 type = string
 default = "perQueue" 
}
 
variable "dedup_scope" { 
 type = string
 default = "messageGroup" 
}
