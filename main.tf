locals {
  name = "prom-graf-lab"
}

// creating igw 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc-main
}



// creating my subnet pub sub1
resource "aws_subnet" "pub-sub1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.pub-sub1-cidr
  availability_zone = "eu-west-2a"

  tags = {
    Name = "pub-sub1"
  }
}

#creating my public route table
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.allcidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "pub-rt"
  }
}

#creating my route table association
resource "aws_route_table_association" "route-table-assocciation" {
  subnet_id      = aws_subnet.pub-sub1.id
  route_table_id = aws_route_table.pub-rt.id
}


#creating my rsa keypair of 4096 bits
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#crating my keypair locally 
resource "local_file" "key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "prom-graf-key"
  file_permission = "600"
}

#registering my keypair on aws 
resource "aws_key_pair" "key" {
  key_name   = "prom-graf-key"
  public_key = tls_private_key.key.public_key_openssh
}


# creating security group
resource "aws_security_group" "prom_graf_sg" {
  name        = "prom-graf-sg"
  description = "prom-graf instance security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh port"
    from_port   = 22  # to connect the instance using ssh
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  ingress {
    description = "application port"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  ingress {
    description = "api server port"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

    ingress {
    description = "etcd directory port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  egress {
    from_port   = 0  # allow all outbound traffic
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allcidr]
  }

  tags = {
    Name = "${local.name}-prom_graf_sg"
  }
}

resource "aws_security_group" "target_sg" {
  name        = "target-sg"
  description = "target instance security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  ingress {
    description = "kubelet api port"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.allcidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allcidr]
  }

  tags = {
    Name = "${local.name}-workernode_sg"
  }
}

//creating ansible instance
resource "aws_instance" "prom_graf_instance" {
  ami                         = var.ubuntu
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.key.key_name
  subnet_id                   = aws_subnet.pub-sub1.id
  vpc_security_group_ids      = [aws_security_group.prom_graf_sg.id]
  associate_public_ip_address = true
  user_data                   = file("./userdata1.sh")

  tags = {
    Name = "prom-graf-instance"
  }
}

resource "aws_instance" "target_instance" {
  ami                         = var.ubuntu
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.key.key_name
  subnet_id                   = aws_subnet.pub-sub1.id
  vpc_security_group_ids      = [aws_security_group.target_sg.id]
  associate_public_ip_address = true
  user_data                   = file("./userdata2.sh")

  tags = {
    Name = "target-instance"
  }
}