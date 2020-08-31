provider "random" {}

module "tags_network" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "phi_DevOps"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "network"
  }
}

module "tags_worker" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "phi_worker-devops-bootcamp"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "worker"
    Name  = format("worker-%s", var.name)
  }
}

module "tags_controlplane" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "phi_controlplane-devops-bootcamp"
  delimiter   = "_"

  tags = {
    owner = var.name
    type  = "controlplane"
  }
}

data "aws_ami" "latest_server" {
  most_recent = true
  owners      = ["772816346052"]

  filter {
    name   = "name"
    values = ["phi-k3s-server*"]
  }
}

data "aws_ami" "latest_agent" {
  most_recent = true
  owners      = ["772816346052"]

  filter {
    name   = "name"
    values = ["phi-k3s-agent*"]
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  tags                 = module.tags_network.tags
  enable_dns_hostnames = true
}

resource "aws_route53_zone" "phi_com" {
  name = "phi.com"
  tags = module.tags_network.tags

  vpc {
    vpc_id = aws_vpc.lab.id
  }
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_network.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.lab.main_route_table_id
  gateway_id             = aws_internet_gateway.lab_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_subnet" "worker" {
  count                   = 2
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = format("10.0.%s.0/24", count.index + 10)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = module.tags_worker.tags
}

resource "aws_subnet" "controlplane" {
  count                   = 1
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = format("10.0.%s.0/24", count.index + 20)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = module.tags_controlplane.tags
}

resource "aws_security_group" "controlplane" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_controlplane.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port       = 12345
    to_port         = 12345
    protocol        = "tcp"
    security_groups = [aws_security_group.worker.id]
  }
  
  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    cidr_blocks     =["0.0.0.0/0"]
  }
 
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     =["0.0.0.0/0"]
  }

  ingress {
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    cidr_blocks     =["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     =["0.0.0.0/0"]
  }

}

//added 
resource "random_id" "keypair" {
  keepers = {
    public_key = file(var.public_key_path)
  }

  byte_length = 8
}

resource "aws_security_group" "worker" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_worker.tags
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     =["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     =["0.0.0.0/0"]
  }

}

/*resource "aws_security_group_rule" "egress_to_all" {
  type              = "egress"
  security_group_id = aws_security_group.worker.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
*/
/*
resource "aws_security_group_rule" "ssh_from_conrtolplan" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.controlplane.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}
*/
/*
resource "aws_security_group_rule" "all_from_control_plane" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.controlplane.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}
*/

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s_keypair_%s", var.name, random_id.keypair.hex)
  public_key = random_id.keypair.keepers.public_key
}

resource "aws_route53_record" "controlplane" {
  zone_id = aws_route53_zone.phi_com.id
  name    = "controlplane"
  type    = "A"
  ttl     = 300
  records = [aws_instance.controlplane.0.private_ip]
}

resource "aws_instance" "controlplane" {
  count                  = 1
  ami                    = data.aws_ami.latest_server.id
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.controlplane[count.index].id
  vpc_security_group_ids = [aws_security_group.controlplane.id]
  tags                   = module.tags_controlplane.tags
  
  //added
   key_name               = aws_key_pair.lab_keypair.id
}

resource "aws_instance" "worker" {
  count                  = 2
  ami                    = data.aws_ami.latest_agent.id
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.worker[count.index].id
  vpc_security_group_ids = [aws_security_group.worker.id]
  tags                   = module.tags_worker.tags
  provisioner "remote-exec" {

  inline = [ 
  "sudo echo K3S_HOST=controlplane.phi.com >> /etc/environment",
  "sudo echo K3S_TOKEN=$(nc.traditional $K3S_HOST 12345) >> /etc/environment",
  "sudo echo K3S_URL=https://$K3S_HOST:6443 >> /etc/environment",
  "env",
  "curl -sfL https://get.k3s.io | sh -",
  ]

  connection {
  type = "ssh"
  user = "ubuntu"
  host = self.private_ip
  private_key = file("./ssh/id_rsa")
  //bastion_host = aws_instance.controlplane.0.public_ip
  //bastion_private_key = file("./ssh/id_rsa")
  //bastion_user = "ubuntu"
  }
  }  
  key_name   = aws_key_pair.lab_keypair.id
  depends_on = [
    aws_instance.controlplane
  ]
}
