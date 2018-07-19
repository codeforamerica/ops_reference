terraform {
  backend "s3" {
    bucket = "terraform-state-ops-reference"
    region = "us-east-1"
    key = "state.tf"
  }
}

# Configure the AWS Provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "us-east-1"
}

variable "access_key" {}
variable "secret_key" {}
variable "project_name" {}
variable "rails_master_key" {}

resource "aws_elastic_beanstalk_application" "beanstalk_app" {
  name = "${var.project_name}"
}

resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name = "${var.project_name}-development"
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
}
