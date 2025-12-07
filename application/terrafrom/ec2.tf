#  control_plane ec2
resource "aws_instance" "control_plane" {
  ami                         = var.ami
  instance_type               = var.instance_type_t2_medium
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false

  key_name = aws_key_pair.ssh_key_pair.key_name

  tags = {
    Name = "control-plane"
  }
}
#  worker ec2
resource "aws_instance" "worker" {
  ami                         = var.ami
  instance_type               = var.instance_type_t2_medium
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false

  key_name = aws_key_pair.ssh_key_pair.key_name

  tags = {
    Name = "worker"
  }
}
# associate a EIP to fe_lb
resource "aws_eip_association" "fe_assoc" {
  instance_id   = aws_instance.fe_lb.id
  allocation_id = var.fe_eip_allocation_id
}
#  fe_lb ec2
resource "aws_instance" "fe_lb" {
  ami                    = var.ami
  instance_type          = var.instance_type_t2_small
  subnet_id              = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  associate_public_ip_address = false

  key_name = aws_key_pair.ssh_key_pair.key_name

  tags = {
    Name = "fe-lb"
  }
}
# associate a EIP to be_lb
resource "aws_eip_association" "be_assoc" {
  instance_id   = aws_instance.be_lb.id
  allocation_id = var.be_eip_allocation_id
}
# be_lb ec2
resource "aws_instance" "be_lb" {
  ami                    = var.ami
  instance_type          = var.instance_type_t2_small
  subnet_id              = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
 
  associate_public_ip_address = false

  key_name = aws_key_pair.ssh_key_pair.key_name

  tags = {
    Name = "be-lb"
  }
}

# monitoring ec2
resource "aws_instance" "monitoring" {
  ami                         = var.ami
  instance_type               = var.instance_type_t2_medium
  subnet_id                   = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.ssh_key_pair.key_name

  tags = {
    Name = "monitoring"
  }
}

# Create private key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}
resource "local_file" "monitoring_private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/ssh-key.pem"
  file_permission = "0400"
}