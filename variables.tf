// Set project tags
variable "tags" {
  type = map(any)

  default = {
    terraform = true
    project   = "tfdeploy"
  }
}

// Set prefix for name tag
variable "prefix" {
  type = string

  default = "makena-"
}

// Set DB account data
variable "db_user" {
  type = string
}

variable "db_pw" {
  type = string
}

// Set availability zones
variable "az" {
  type = list(string)

  default = ["us-east-1a", "us-east-1b"]
}

// Set all traffic
variable "sg_all" {
  type = list(string)

  default = ["0.0.0.0/0"]
}

// Set AMI ID, instance type, and key name
variable "instance" {
  type = map(any)

  default = {
    ami           = "ami-005f9685cb30f234b"
    instance_type = "t2.micro"
    key_name      = "makena-test"
  }
}