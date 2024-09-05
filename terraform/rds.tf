# ======================================================================================
# RDS
# ======================================================================================

resource "random_string" "medusa_db_password" {
  length  = 32
  special = false
}

resource "aws_db_instance" "medusa_rds" {
  identifier             = "medusa-rds-instnce"
  db_name = "medusadb"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "12.5"
  skip_final_snapshot    = true
  db_subnet_group_name = aws_subnet.medusa_app_persistance.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  username               = "medusadbuser"
  password               = "random_string.medusa_db_password.result}"
}

resource "aws_security_group" "rds_sg" {
  vpc_id      = "${aws_vpc.medusa_vpc.id}"
  name        = "rds_sg"
  description = "Allow all inbound for Postgres"
ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name = "rds-subnet"
  subnet_ids = [aws_subnet.private_persistance.id]

  tags = {
    Name = "rds-subnet"
  }
}