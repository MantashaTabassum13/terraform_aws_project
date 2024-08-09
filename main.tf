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
    cidr_blocks = ["0.0.0./0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0./0"]
  }
    tags = {
    Name = "Web-sg"
  }
}
resource "aws_s3_bucket" "my_bkt" {
    bucket = mantashaterraformbuckethaiye  
}

resource "aws_instance" "ec2_1" {
  ami = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.scg.id ]
  subnet_id = aws_subnet.my_sb1.id
  user_data = base64decode(file(userdata.sh))
}

resource "aws_instance" "ec2_2" {
  ami = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.scg.id ]
  subnet_id = aws_subnet.my_sb2.id
  user_data = base64decode(file(userdata1.sh))
}

