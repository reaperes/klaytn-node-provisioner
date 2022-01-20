variable "instance-name" {
  type = string
}

variable "instance-type" {
  type = string
  default = "t2.medium"
}

variable "instance-ami" {
  type = string
  default = ""
}

variable "instance-key-pair" {
  type = string
  default = null
}

variable "instance-subnet-id" {
  type = string
}

variable "device-name" {
  type = string
  default = "/dev/sdf"
}

variable "device-volume" {
  type = number
  default = 1000  # GiB
}

variable "device-mount-dir" {
  type = string
}

variable "vpc-security-group-ids" {
  type = list(string)
  default = null
}

# latest amazon-linux-2 ami
data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.*-hvm-2.*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "instance" {
  ami                         = var.instance-ami != "" ? var.instance-ami : data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance-type
  key_name                    = var.instance-key-pair
  subnet_id                   = var.instance-subnet-id
  vpc_security_group_ids      = var.vpc-security-group-ids
  associate_public_ip_address = true
  user_data                   = templatefile("userdata.tftpl", { deviceName = var.device-name, mountDir = var.device-mount-dir })

  tags = {
    Name = var.instance-name
  }

  ebs_block_device {
    device_name = var.device-name
    volume_size = var.device-volume
    volume_type = "gp2"
  }
}

output "publicIp" {
  value = aws_instance.instance.public_ip
}
