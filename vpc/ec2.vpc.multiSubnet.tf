provider "aws" {
    profile = "vktf"
}

resource "aws_instance" "projectinstance" {
  
  ami="ami-0230bd60aa48260c6"
  key_name = "terraformkey2"
  #availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  tags = {
    Name=   "projectinstance"
  }
  vpc_security_group_ids =  [ aws_security_group.moto_sg.id]
  subnet_id = aws_subnet.subnet_moto_pubA.id
}
resource "aws_security_group" "moto_sg" {
  name        = "moto_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.VPCmoto.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "moto_sg"
  }
}

resource "null_resource" "remoteconnectssh" {
    connection {
      
      type = "ssh"
      private_key = file("~/downloads/terraformkey2.pem")
      host = aws_instance.projectinstance.public_ip
      user="ec2-user"

    }

    provisioner "remote-exec" {
      inline = [ 
        #"sudo amazon-linux-extras install nginx1",
        "sudo yum install nginx -y",
        "sudo systemctl enable nginx --now",
        "sudo sh -c 'echo this is a test web page > /usr/share/nginx/html/index.html '"
       ]
    }
     
}

resource "aws_vpc" "VPCmoto" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name="VPCmoto"
  }
}

data "aws_availability_zones" "AZmoto" {
    state = "available"
  
}

resource "aws_subnet" "subnet_moto_pubA" {
    availability_zone = "${data.aws_availability_zones.AZmoto.names[0]}"
    cidr_block = "10.1.1.0/24"
    vpc_id = aws_vpc.VPCmoto.id
    map_public_ip_on_launch = true
    tags = {
      Name="subnet_moto_pubA"
    }
  
}
resource "aws_subnet" "subnet_moto_pubB" {
    availability_zone = "${data.aws_availability_zones.AZmoto.names[1]}"
    cidr_block = "10.1.2.0/24"
    vpc_id = aws_vpc.VPCmoto.id
    map_public_ip_on_launch = true
    tags = {
      Name="subnet_moto_pubB"
    }
  
}
resource "aws_subnet" "subnet_moto_priA" {
    availability_zone = "${data.aws_availability_zones.AZmoto.names[2]}"
    cidr_block = "10.1.3.0/24"
    vpc_id = aws_vpc.VPCmoto.id
    map_public_ip_on_launch = false
    tags = {
      Name="subnet_moto_priA"
    }
  
}
resource "aws_subnet" "subnet_moto_priB" {
    availability_zone = "${data.aws_availability_zones.AZmoto.names[3]}"
    cidr_block = "10.1.4.0/24"
    vpc_id = aws_vpc.VPCmoto.id
    map_public_ip_on_launch = false
    tags = {
      Name="subnet_moto_priB"
    }
  
}
output "vpc_out" {
  value = "${aws_vpc.VPCmoto}"
}

output "az_out" {
  value = "${data.aws_availability_zones.AZmoto}"
}


resource "aws_internet_gateway" "projectIgway" {
    vpc_id = aws_vpc.VPCmoto.id
    tags = {
      Name= "projectIgway"
    }
  
}
resource "aws_route_table" "projectRouteTable" {
    vpc_id = aws_vpc.VPCmoto.id
    route  {
        cidr_block= "0.0.0.0/0"
        gateway_id = aws_internet_gateway.projectIgway.id
    }
  tags = {
    Name="projectRouteTable"
  }
}

resource "aws_route_table_association" "projectRTASSO" {
    subnet_id = aws_subnet.subnet_moto_pubA.id
    route_table_id = aws_route_table.projectRouteTable.id
}
resource "aws_route_table_association" "projectRTASSO2" {
    subnet_id = aws_subnet.subnet_moto_pubB.id    
    route_table_id = aws_route_table.projectRouteTable.id
}
