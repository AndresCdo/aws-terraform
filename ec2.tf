# Create a EC2 instance
resource "aws_instance" "dev_node" {
  instance_type = "t2.nano"
  ami = data.aws_ami.server_ami.id
  key_name = aws_key_pair.main_authorization.id
  vpc_security_group_ids = [aws_security_group.main_security_group.id]
  subnet_id = aws_subnet.main_public_network.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("ssh-config.tpl", {
      hostname = self.public_ip,
      user = "ubuntu",
      identityfile = "~/.ssh/main_key"
    })    
  }
}