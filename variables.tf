variable "tags" {
  type = map(any)

  default = {
    terraform = true
    project   = "tfdeploy"
  }
}

variable "prefix" {
  type = string

  default = "makena-"
}

variable "db_user" {
  type = string
}

variable "db_pw" {
  type = string
}

variable "az" {
  type = list(string)

  default = ["us-east-1a", "us-east-1b"]
}

variable "sg_all" {
  type = list(string)

  default = ["0.0.0.0/0"]
}

variable "instance" {
  type = map(any)

  default = {
    ami           = "ami-005f9685cb30f234b"
    instance_type = "t2.micro"
    key_name      = "makena-test"
  }
}