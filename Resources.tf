# VPC Resource 
# ---------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Project-vpc"
  }
}
#-----------------------------------------------------
# Public Subnets
# ----------------------------------------------------
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-1a"

  tags = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-1c"

  tags = { Name = "public-subnet-2" }
}

# -----------------------------------------------------
# Private Subnets
# -----------------------------------------------------
resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-1a"

  tags = { Name = "private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-west-1c"

  tags = { Name = "private-subnet-2" }
}

resource "aws_subnet" "private_3" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-west-1a"

  tags = { Name = "private-subnet-3" }
}

resource "aws_subnet" "private_4" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-west-1c"

  tags = { Name = "private-subnet-4" }
}

#-----------------------------------------------
# Route Tables
# ---------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-rt" }
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_3_assoc" {
  subnet_id      = aws_subnet.private_3.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_4_assoc" {
  subnet_id      = aws_subnet.private_4.id
  route_table_id = aws_route_table.private_rt.id
}

# ----------------------------------------------------------------
# Internet Gateway
# ----------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Project-igw"
  }
}


# ----------------------------------------------------------------
# NAT Gateway + EIP
# -----------------------------------------------------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = { Name = "Project-nat-gateway" }
}

# -------------------------------
# Security Groups
# -------------------------------
resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow traffic from public tier"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow DB access from private tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.private_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# -------------------------------
# EC2 in Public Subnets
# -------------------------------
resource "aws_instance" "public_ec2_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1.id
  security_groups = [aws_security_group.public_sg.id]

  tags = { Name = "public-ec2-1" }
}


resource "aws_instance" "public_ec2_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_2.id
  security_groups = [aws_security_group.public_sg.id]

  tags = { Name = "public-ec2-2" }
}



# -------------------------------
# Public Application Load Balancer
# -------------------------------

resource "aws_lb" "public_alb" {
  name               = "public-app-lb"
  internal           = false                    
  load_balancer_type = "application"
  subnets            = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
  security_groups    = [aws_security_group.public_sg.id]

  tags = {
    Name = "public-alb"
  }
}

resource "aws_lb_target_group" "public_tg" {
  name     = "public-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
    protocol = "HTTP"
    port = "80"
  }
}

resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}

# -------------------------------
# Attach Public EC2 to Public ALB
# -------------------------------
resource "aws_lb_target_group_attachment" "public_ec2_attach_1" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.public_ec2_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "public_ec2_attach_2" {
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.public_ec2_2.id
  port             = 80
}


# -------------------------------
# Private EC2
# -------------------------------
resource "aws_instance" "private_ec2_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_1.id
  security_groups = [aws_security_group.private_sg.id]

  tags = { Name = "private-ec2-1" }
}

resource "aws_instance" "private_ec2_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_2.id
  security_groups = [aws_security_group.private_sg.id]

  tags = { Name = "private-ec2-2" }
}


# -------------------------------
# Private Application Load Balancer
# -------------------------------

resource "aws_lb" "private_alb" {
  name               = "private-app-lb"
  internal           = true                    
  load_balancer_type = "application"
  subnets            = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
  security_groups    = [aws_security_group.private_sg.id]

  tags = {
    Name = "private-alb"
  }
}

resource "aws_lb_target_group" "private_tg" {
  name     = "private-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
    protocol = "HTTP"
    port = "80"
  }

  tags = {
    Name = "private-tg"
  }
}

resource "aws_lb_listener" "private_listener" {
  load_balancer_arn = aws_lb.private_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_tg.arn
  }
}

# -------------------------------
# Attach Private EC2 to Pravite ALB
# -------------------------------
resource "aws_lb_target_group_attachment" "private_ec2_attach_1" {
  target_group_arn = aws_lb_target_group.private_tg.arn
  target_id        = aws_instance.private_ec2_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "private_ec2_attach_2" {
  target_group_arn = aws_lb_target_group.private_tg.arn
  target_id        = aws_instance.private_ec2_2.id
  port             = 80
}



# -------------------------------
# RDS Master + Read Replica
# -------------------------------
resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnet-group"
  subnet_ids = [
    aws_subnet.private_3.id,
    aws_subnet.private_4.id
  ]

  tags = { Name = "db-subnet-group" }
}

resource "aws_db_instance" "db" {
  identifier           = "main-db"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Admin12345"
  allocated_storage    = 20
  backup_retention_period = 1
  skip_final_snapshot  = true
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_db_instance" "read_replica" {
  identifier           = "read-replica"
  replicate_source_db  = aws_db_instance.db.arn
  instance_class       = "db.t3.micro"
  publicly_accessible  = false
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}


