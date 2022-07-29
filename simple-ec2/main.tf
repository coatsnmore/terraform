data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*amzn2-ami-hvm-*-x86_64-gp2"]

  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

variable "awsprops" {
  type = map(string)
  default = {
    region = "us-east-1"
    # vpc          = "vpc-5234832d"
    # ami   = "ami-0c1bea58988a989155"
    itype = "t2.micro"
    # subnet       = "subnet-81896c8e"
    publicip     = true
    keyname      = "coatsn-key"
    secgroupname = "coatsnmore-sg"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}

resource "aws_security_group" "project-iac-sg" {
  name        = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  #   vpc_id      = lookup(var.awsprops, "vpc")

  // To Allow SSH Transport
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "project-iac" {
  ami           = data.aws_ami.linux.id
  instance_type = lookup(var.awsprops, "itype")
  #   subnet_id                   = lookup(var.awsprops, "subnet") #FFXsubnet2
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name                    = lookup(var.awsprops, "keyname")


  vpc_security_group_ids = [
    aws_security_group.project-iac-sg.id
  ]
  root_block_device {
    delete_on_termination = true
    # iops                  = 150
    volume_size = 100
    volume_type = "gp2"
  }
  tags = {
    Name        = "coatsn-tf-ubuntu"
    Environment = "DEV"
    OS          = "UBUNTU"
    Managed     = "IAC"
  }

  depends_on = [aws_security_group.project-iac-sg]
}


output "ec2instance" {
  value = aws_instance.project-iac.public_ip
}
