provider "aws" {
  profile = "vktf"
  region = "us-east-1"
}

resource "aws_instance" "projectinstance" {
  
  ami="ami-0230bd60aa48260c6"
  key_name = "terraformkey2"
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  tags = {
    Name=   "projectinstance"
  }
  vpc_security_group_ids =  [ aws_security_group.allow_tls.id]
}
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.projectVPC.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
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
    Name = "allow_tls"
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

output "publicip" {
    value = aws_instance.projectinstance.public_ip
  
}

resource "aws_vpc" "projectVPC" {
    cidr_block = "10.1.0.0/16"
    tags = {
      Name = "projectVPC"
    }
  
}

resource "aws_subnet" "projectSubnet-pubA" {
    vpc_id = aws_vpc.projectVPC.id
    cidr_block = "10.1.1.0/24"
    availability_zone = "us-east-1a"
    tags ={
        Name= "projectSubnet-pubA"
    }  
    map_public_ip_on_launch = true
}



resource "aws_subnet" "projectSubnet-priA" {
    vpc_id = aws_vpc.projectVPC.id
    cidr_block = "10.1.3.0/24"
    availability_zone = "us-east-1c"
    tags ={
        Name= "projectSubnet-priA"
    }  
    
}



resource "aws_internet_gateway" "projectIgway" {
    vpc_id = aws_vpc.projectVPC.id
    tags = {
      Name= "projectIgway"
    }
  
}
resource "aws_route_table" "projectRouteTable" {
    vpc_id = aws_vpc.projectVPC.id
    route = {
        cidr_block= "0.0.0.0/0"
        gateway_id = aws_internet_gateway.projectIgway.id
    }
  tags = {
    Name="projectRouteTable"
  }
}

resource "aws_route_table_association" "projectRTASSO" {
     subnet_id = aws_subnet.projectSubnet.pubA.id 
  
  route_table_id = aws_route_table.projectRouteTable.id
}
output "igway" {
    value = aws_internet_gateway.projectIgway.id
  
}
