provider "aws" {
  region = "eu-central-1"
}


resource "aws_instance" "my_webserver" {
  ami                    = "ami-03c3a7e4263fd998c"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  tags = {
    Name = "MyUbuntu"
  }

  lifecycle {
    //  prevent_destroy = true  не дає знищити сервер
    //  ignore_changes = ["user_data"]  ігнорить зміни для обраних параметрів
    create_before_destroy = true
  }


  user_data = <<EOF
#!/bin/bash
yum -y update
yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<p>Hello Kyrylo</p><h2>WebServer with IP: $myip</h2><br>Build by Terraform!" >  /var/www/html/index.html
sudo service httpd start
chkconfig httpd on

EOF

}
#
# resource "aws_eip_association" "my_static_ip" {
#   instance_id   = aws_instance.my_webserver.id
#   allocation_id = "eipalloc-8de8aeaf"
# }


resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_webserver.id
}

resource "aws_security_group" "my_webserver" {
  name        = "Web Server Security Group"
  description = "Allow TLS inbound traffic"

  dynamic "ingress" {
    for_each = ["443", "80"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "webserver_instance_id" {
  value = aws_instance.my_webserver.id
}


output "webserver_public_ip_address" {
  value = aws_eip.my_static_ip.public_ip
}
