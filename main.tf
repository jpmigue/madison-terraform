# Security Groups

resource "aws_key_pair" "jpmawsterra_rsa" {
  key_name	= "jpmawsterra_rsa"
  public_key	= "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEApBiAPxcO0XDeL7FbbPTp1wzcU/xdFJtD9HP7+06iqnarn+bKrtn8DG2mMT0+CHsb+pKDp3wlnKYqQuHwmzmz29BP+uD7/bQsFUvFY0mjSeAmavZSwTp9xibiD0mk2ZoQb0iW5eXovEaxFottn0Rr3+rnyTkTXscg5NdmS97I5xl1CjO7wLWpgCI/6QvNeY5qun5syhd1Ptl7zHMhEAhEtU4ZEFptW0vCIHjVmoL3jRKDMccjgp9yvdShbnisuiMxCwopYLrsQnLQcn4K+8OjlRUKsgzcnYi4q6x2ATXf829iv0kIRkS/oXfxG91xp/oqmkhWNxgla+p67u/kTpKHKw== rsa-key-20180509"
}

resource "aws_security_group" "ss-webserver" {
  name="ss-webserver"
  vpc_id	= "vpc-d76c55be"
  ingress = [
    {
      from_port	= 22
      to_port	= 22
      protocol	= "tcp"
      cidr_blocks	= ["10.71.100.0/23"]
    },
    {
      from_port	= 80
      to_port	= 80
      protocol	= "tcp"
      cidr_blocks	= ["10.71.100.0/23"]
    }
  ]
}

resource "aws_security_group" "ss-appserver" {
  name="ss-appserver"
  vpc_id	= "vpc-d76c55be"
  ingress = [
    {
      from_port	= 22
      to_port	= 22
      protocol	= "tcp"
      cidr_blocks	= ["10.71.100.0/23"]
    }, 
    {
      from_port	= 80
      to_port	= 80
      protocol	= "tcp"
      cidr_blocks	= ["10.71.100.0/23"]
    },
    {
      from_port	= 8009
      to_port	= 8010
      protocol	= "tcp"
      # cidr_blocks	= ["${aws_subnet.subnet-ae3674e3.cidr}"]
      cidr_blocks	= ["${aws_instance.ss-webserver.0.private_ip}/32"]
      cidr_blocks	= ["${aws_instance.ss-webserver.1.private_ip}/32"]
      # cidr_blocks	= ["172.17.0.0/24"]
    }
  ]
  egress {
    from_port	= 0
    to_port	= 0
    protocol	= "-1"
    cidr_blocks	= ["0.0.0.0/0"]
  }
}


# Servers

resource "aws_instance" "ss-webserver" {
  ami				= "ami-20997a47"
  instance_type 		= "t2.micro"
  key_name			= "${aws_key_pair.jpmawsterra_rsa.key_name}"
  count				= 2
  subnet_id			= "subnet-ae3674e3"
  vpc_security_group_ids	= ["${aws_security_group.ss-webserver.id}"]
  tags {
    Name = "ss-madison-web${count.index+1}"
  }
  # output "private_ip" {
    # value = "${aws_instance.ss-webserver.private_ip}"
  # }

  user_data = <<EOF
        #!/bin/bash
	sudo yum -y install nmap
        sudo yum -y install nginx
        sudo service start nginx     
	EOF
}

resource "aws_instance" "ss-appserver" {
  ami				= "ami-20997a47"
  instance_type			= "t2.micro"
  key_name			= "${aws_key_pair.jpmawsterra_rsa.key_name}"
  count				= 2
  subnet_id			= "subnet-39367474"
  vpc_security_group_ids	= ["${aws_security_group.ss-appserver.id}"]
  tags {
     Name = "ss-madison-app${count.index+1}"
  }

}

# Outputs

output "mykey" {
  value = "${aws_key_pair.jpmawsterra_rsa.key_name}"
}

output "web_private_ip" {
  value = "${aws_instance.ss-webserver.*.private_ip}"
}

output "app_private_ip" {
  value = "${aws_instance.ss-appserver.*.private_ip}"
}

