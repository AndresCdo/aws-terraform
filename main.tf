resource "null_resource" "remove_local_file" {
  provisioner "local-exec" {
    command = "rm -f ~/.ssh/main_key"
  }

  provisioner "local-exec" {
    command = "rm -f ~/.ssh/main_key.pub"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "create_ssh_credentials" {
  depends_on = [ null_resource.remove_local_file ]
  provisioner "local-exec" {
    command = "openssl rand -base64 8 | tr -cd '[:alpha:]' > ~/passphrase.txt"
  }

  provisioner "local-exec" {
    command = "echo 'yes' | ssh-keygen -t ed25519 -f ~/.ssh/main_key -P $(cat ~/passphrase.txt)"
  }
}

# data "local_file" "ssh_public_key" {
#   depends_on = [ null_resource.create_ssh_credentials ]
#   filename = "~/.ssh/main_key.pub"
# }

resource "aws_key_pair" "main_authorization" {
  # depends_on = [ data.local_file.ssh_public_key ]
  key_name   = "mainkey"
  public_key = file("~/.ssh/main_key.pub")
}


# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "main_public_network" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"

  tags = {
    Name = "dev-public",
  }
}

resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "aws_internet_gateway",
  }
}

resource "aws_route_table" "main_public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev_public_route_table",
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_internet_gateway.id
}

resource "aws_route_table_association" "main_public_association" {
  subnet_id      = aws_subnet.main_public_network.id
  route_table_id = aws_route_table.main_public_route_table.id
}

resource "aws_security_group" "main_security_group" {
  name        = "dev_security_group"
  description = "Development Environment security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}