# STEP1 START HERE
terraform {
  backend "s3" {
    bucket = "terraform-state-ops-reference"
    region = "us-east-1"
    key = "state.tf"
  }
}

# STEP2 Need these variables for the provider
variable "access_key" {}
variable "secret_key" {}

# STEP3 Configure the AWS Provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "us-east-1"
}

# STEP4 start with a vpc
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# STEP5 Then comes an IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "default"
  }
}

# STEP6 we know we'll need 4 subnets

resource "aws_subnet" "public_1" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.0.3.0/24"

  availability_zone = "us-east-1a"

  tags {
    Name = "public 1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.0.4.0/24"

  availability_zone = "us-east-1b"

  tags {
    Name = "public 2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-1a"

  tags {
    Name = "private 1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.0.2.0/24"

  availability_zone = "us-east-1b"

  tags {
    Name = "private 2"
  }
}

# STEP7 We'll need elastic IPs for our permanent public devices

resource "aws_eip" "public_1" {}

resource "aws_eip" "public_2" {}

# STEP8

resource "aws_nat_gateway" "public_1" {
  allocation_id = "${aws_eip.public_1.id}"
  subnet_id     = "${aws_subnet.public_1.id}"

  tags {
    Name = "Public 1 NAT"
  }
}

resource "aws_nat_gateway" "public_2" {
  allocation_id = "${aws_eip.public_2.id}"
  subnet_id     = "${aws_subnet.public_2.id}"

  tags {
    Name = "Public 2 NAT"
  }
}

# STEP9 Need a route table for the IGW

resource "aws_route_table" "gw_route" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public"
  }
}

# STEP10 Now to associate the public route

resource "aws_route_table_association" "gw_public_1" {
  subnet_id      = "${aws_subnet.public_1.id}"
  route_table_id = "${aws_route_table.gw_route.id}"
}

resource "aws_route_table_association" "gw_public_2" {
  subnet_id      = "${aws_subnet.public_2.id}"
  route_table_id = "${aws_route_table.gw_route.id}"
}

# STEP11 And private routes through the nat

resource "aws_route_table" "nat_route_private_1" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.public_1.id}"
  }

  tags {
    Name = "private 1 route"
  }
}

resource "aws_route_table" "nat_route_private_2" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.public_2.id}"
  }

  tags {
    Name = "private 2 route"
  }
}

# STEP12 And associate the private routes

resource "aws_route_table_association" "nat_private_1" {
  subnet_id      = "${aws_subnet.private_1.id}"
  route_table_id = "${aws_route_table.nat_route_private_1.id}"
}

resource "aws_route_table_association" "nat_private_2" {
  subnet_id      = "${aws_subnet.private_2.id}"
  route_table_id = "${aws_route_table.nat_route_private_2.id}"
}

# STEP13 subnet groups

resource "aws_db_subnet_group" "rds" {
  name       = "rds"
  subnet_ids = ["${aws_subnet.private_1.id}", "${aws_subnet.private_2.id}"]

  tags {
    Name = "DB subnet group"
  }
}

# STEP14 Release the database

resource "random_string" "rds_password" {
  length = 30
  special = false
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "postgres"
  instance_class       = "db.t2.micro"
  name                 = "ops_reference_production"
  username             = "ops_reference"
  password             = "${random_string.rds_password.result}"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.rds.name}"
  skip_final_snapshot = true
}

# STEP15 fix the surprise issue - we need some security groups

resource "aws_security_group" "rds" {
  name = "rds_security"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.application.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "application" {
  name = "application"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.load_balancer.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "load_balancer" {
  name = "load_balancer"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

# STEP16 a chance to talk about instance profiles and iam roles

resource "aws_iam_instance_profile" "default" {
  name = "default"
  role = "${aws_iam_role.default.name}"
}

resource "aws_iam_role" "default" {
  name = "default"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

# STEP17 we're ready for the actual application

variable "project_name" {}
variable "stage_name" {}
variable "rails_master_key" {}



resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name = "${var.project_name}"
}

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name = "${var.project_name}-${var.stage_name}"
  application = "${aws_elastic_beanstalk_application.beanstalk_app.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.8.1 running Ruby 2.5 (Puma)"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.small"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RAILS_MASTER_KEY"
    value = "${var.rails_master_key}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DATABASE_URL"
    value = "postgresql://${aws_db_instance.default.username}:${random_string.rds_password.result}@${aws_db_instance.default.endpoint}/${aws_db_instance.default.name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "enhanced"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "${aws_iam_instance_profile.default.arn}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${aws_vpc.default.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = "${aws_subnet.private_1.id},${aws_subnet.private_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = "${aws_subnet.public_1.id},${aws_subnet.public_2.id}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name = "SecurityGroups"
    value = "${aws_security_group.load_balancer.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.application.id}"
  }
}
