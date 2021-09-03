
data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["309956199498"]
  filter {
    name   = "name"
    values = ["RHEL-8*"]
  }
}
resource "aws_instance" "nodejs" {
    ami = data.aws_ami.rhel8.id
    instance_type = "t2.micro"
    iam_instance_profile = var.master_profile_name
    vpc_security_group_ids = [aws_security_group.matt-nodejs-sg.id]
    key_name = var.key_name
    subnet_id = var.public_subnets
    tags = {
        Name = "ansible_nodejs"
        environment = "development"
        stack = "ansible_project"
        
    }
}

resource "aws_instance" "react" {
    ami = data.aws_ami.rhel8.id
    instance_type = "t2.micro"
    count         = var.instance_count
    iam_instance_profile = var.worker_profile_name
    vpc_security_group_ids = [aws_security_group.matt-react-sg.id]
    key_name = var.key_name
    subnet_id = var.public_subnets
    tags = {
        Name = "ansible_react"
        environment = "development"
        stack = "ansible_project"
    }
}

resource "aws_instance" "postgress" {
    ami = data.aws_ami.rhel8.id
    instance_type = "t2.micro"
    iam_instance_profile = var.worker_profile_name
    vpc_security_group_ids = [aws_security_group.matt-postgress-sg.id]
    key_name = var.key_name
    subnet_id = var.public_subnets
    tags = {
        Name = "ansible_postgresql"
        environment = "development"
        stack = "ansible_project"
    }
}

resource "aws_security_group" "matt-postgress-sg" {
  name = "postgress-sec-group-for-matt"
  vpc_id = var.vpc_id
  
  ingress {
    protocol = "tcp"
    from_port = 5432
    to_port = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  egress{
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "postgress-secgroup"
  }
}

resource "aws_security_group" "matt-nodejs-sg" {
  name = "nodejs-sec-group-for-matt"
  vpc_id = var.vpc_id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 3000
    to_port = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 5000
    to_port = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nodejs-secgroup"
  }
}

resource "aws_security_group" "matt-react-sg" {
  name = "react-sec-group-for-matt"
  vpc_id = var.vpc_id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 3000
    to_port = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 5000
    to_port = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "react-secgroup"
  }
}

resource "aws_lb_target_group_attachment" "mtc_tg_attach" {
  count            = var.instance_count
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.react[count.index].id
  port             = var.tg_port
}