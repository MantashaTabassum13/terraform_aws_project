resource "aws_vpc" "myvpc" {
  cidr_block       = var.cidr
}

resource "aws_subnet" "my_sb1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "my_sb2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "my_gw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }
}

resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.my_sb1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.my_sb2.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_security_group" "scg" {
  name        = "web"
  vpc_id      = aws_vpc.myvpc.id

  ingress  {
    description = "HTTP from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "Web-sg"
  }
}
resource "aws_s3_bucket" "my_bkt" {
    bucket = "mantashaterraformbuckethaiye"  
}

resource "aws_instance" "ec2_1" {
  ami = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.scg.id ]
  subnet_id = aws_subnet.my_sb1.id
  user_data = base64encode(file("userdata.sh"))
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name
}

resource "aws_instance" "ec2_2" {
  ami = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.scg.id ]
  subnet_id = aws_subnet.my_sb2.id
  user_data = base64encode(file("userdata1.sh"))
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name
}

# Create an IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ec2_s3_access_role"
  }
}


# Create an IAM Policy that allows access to the S3 bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  description = "Policy to allow access to the specific S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::mantashaterraformbuckethaiye",
          "arn:aws:s3:::mantashaterraformbuckethaiye/*"
        ]
      }
    ]
  })
}


# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role     = aws_iam_role.ec2_role.name
}

# Attach the Role to EC2 Instances
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}





# resource "aws_lb" "my_lb" {
#   name               = "test-lb-tf"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.scg.id]
#   subnets = [ aws_subnet.my_sb1, aws_subnet.my_sb2 ]
#   tags = {
#     Name="web"
#   }
# }

# resource "aws_lb_target_group" "tg" {
#   name     = "tf-example-lb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.myvpc.id
#   health_check {
#     path = "/"
#     port = 80
#   }
# }

# resource "aws_lb_target_group_attachment" "tga1" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = aws_instance.ec2_1.id
#   port             = 80
# }
# resource "aws_lb_target_group_attachment" "tga2" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = aws_instance.ec2_2.id
#   port             = 80
# }

# resource "aws_lb_listener" "listen" {
#   load_balancer_arn = aws_lb.my_lb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tg.arn
#   }
# }

# output "loadbalancerdns" {
#     value = aws_lb.my_lb.dns_name
  
# }



