# Specify the provider and access details
provider "aws" {
  access_key = "MASKED"
  secret_key = "MASKED"
  region = "${var.region}"
}

# Declare the data source
data "aws_availability_zones" "available" {}


resource "aws_vpc" "localVpc" {
  cidr_block       = "192.168.0.0/16"

 tags = {
    Name = "localVpc"
  }
}


resource "aws_internet_gateway" "localgw" {
  vpc_id = "${aws_vpc.localVpc.id}"

  tags = {
    Name = "local-GW"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id = "${aws_vpc.localVpc.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id = "${aws_vpc.localVpc.id}"
  cidr_block = "192.168.2.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "public-subnet-2"
  }
}
resource "aws_subnet" "private-subnet-1" {
  vpc_id = "${aws_vpc.localVpc.id}"
  cidr_block = "192.168.4.0/23"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = "${aws_vpc.localVpc.id}"
  cidr_block = "192.168.6.0/23"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.localVpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.localgw.id}"
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}

resource "aws_route_table_association" "public2" {
  subnet_id      = "${aws_subnet.public-subnet-2.id}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}


resource "aws_route_table" "private-route-table" {
  vpc_id = "${aws_vpc.localVpc.id}"

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = "${aws_subnet.private-subnet-1.id}"
  route_table_id = "${aws_route_table.private-route-table.id}"
}

resource "aws_route_table_association" "private2" {
  subnet_id      = "${aws_subnet.private-subnet-2.id}"
  route_table_id = "${aws_route_table.private-route-table.id}"
}


resource "aws_network_acl" "public-ACLs" {
  vpc_id = "${aws_vpc.localVpc.id}"
  subnet_ids = ["${aws_subnet.public-subnet-1.id}", "${aws_subnet.public-subnet-2.id}"]
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "public-ACLs"
  }
}

resource "aws_network_acl" "private-ACLs" {
  vpc_id = "${aws_vpc.localVpc.id}"
  subnet_ids = ["${aws_subnet.private-subnet-1.id}", "${aws_subnet.private-subnet-2.id}"]
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

   ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "185.100.71.242/32"
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "private-ACLs"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }

}


resource "aws_security_group" "defaultsg" {
  name        = "custom-security-group-sks"
  tags = {
    Name = "custom-security-group-sks"
  }
  description = "minimal security group for test"
  vpc_id = "${aws_vpc.localVpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # kafka port access from myIP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "ec2-node1" {
  instance_type = "t2.micro"
  ami = "${data.aws_ami.amazon_linux.id}"
  key_name = "sks_practice"

  # Our Security group to allow HTTP and SSH access
  security_groups = ["${aws_security_group.defaultsg.id}"]

  subnet_id = "${aws_subnet.public-subnet-1.id}"
  tags = {
    Name = "instance-1"
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install httpd -y
                sudo cd /var/www/html
                sudo echo "Web Server 1" > index.html
                sudo service httpd start
                sudo chkconfig httpd on
                EOF
}

resource "aws_eip" "ip1" {
  instance = "${aws_instance.ec2-node1.id}"
}

resource "aws_instance" "ec2-node2" {
  instance_type = "t2.micro"
  ami = "${data.aws_ami.amazon_linux.id}"
  key_name = "sks_practice"

  # Our Security group to allow HTTP and SSH access
  security_groups = ["${aws_security_group.defaultsg.id}"]
  subnet_id = "${aws_subnet.public-subnet-2.id}"
  tags = {
    Name = "instance-2"
  }

    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install httpd -y
                sudo cd /var/www/html
                sudo echo "Web Server 2" > index.html
                sudo service httpd start
                sudo chkconfig httpd on
                EOF

}

resource "aws_eip" "ip2" {
  instance = "${aws_instance.ec2-node2.id}"
}
