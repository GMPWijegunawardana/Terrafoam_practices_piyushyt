provider "aws" {
  region = var.region
}

# ----------------- VPC -----------------
resource "aws_vpc" "manisha_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "manisha-vpc"
  }
}

# ----------------- Subnets -----------------
resource "aws_subnet" "manisha_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.manisha_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.manisha_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "manisha-subnet-${count.index}"
  }
}

# ----------------- Internet Gateway -----------------
resource "aws_internet_gateway" "manisha_igw" {
  vpc_id = aws_vpc.manisha_vpc.id

  tags = {
    Name = "manisha-igw"
  }
}

# ----------------- Route Table -----------------
resource "aws_route_table" "manisha_route_table" {
  vpc_id = aws_vpc.manisha_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.manisha_igw.id
  }

  tags = {
    Name = "manisha-route-table"
  }
}

resource "aws_route_table_association" "manisha_rta" {
  count          = 2
  subnet_id      = aws_subnet.manisha_subnet[count.index].id
  route_table_id = aws_route_table.manisha_route_table.id
}

# ----------------- Security Groups -----------------
resource "aws_security_group" "manisha_cluster_sg" {
  vpc_id = aws_vpc.manisha_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "manisha-cluster-sg"
  }
}

resource "aws_security_group" "manisha_node_sg" {
  vpc_id = aws_vpc.manisha_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "manisha-node-sg"
  }
}

# ----------------- IAM Roles -----------------
resource "aws_iam_role" "manisha_cluster_role" {
  name = "manisha-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "manisha_cluster_policy" {
  role       = aws_iam_role.manisha_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "manisha_node_group_role" {
  name = "manisha-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "manisha_worker_policy" {
  role       = aws_iam_role.manisha_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "manisha_cni_policy" {
  role       = aws_iam_role.manisha_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "manisha_registry_policy" {
  role       = aws_iam_role.manisha_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ----------------- EKS Cluster -----------------
resource "aws_eks_cluster" "manisha_eks_cluster" {
  name     = "manisha-cluster"
  role_arn = aws_iam_role.manisha_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.manisha_subnet[*].id
    security_group_ids = [aws_security_group.manisha_cluster_sg.id]
  }
}

# ----------------- EKS Node Group -----------------
resource "aws_eks_node_group" "manisha_node_group" {
  cluster_name    = aws_eks_cluster.manisha_eks_cluster.name
  node_group_name = "manisha-node-group"
  node_role_arn   = aws_iam_role.manisha_node_group_role.arn
  subnet_ids      = aws_subnet.manisha_subnet[*].id

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = 1
    min_size     = 1
  }

  instance_types = [var.node_instance_type]

  remote_access {
    ec2_ssh_key            = var.ssh_key_name
    source_security_group_ids = [aws_security_group.manisha_node_sg.id]
  }
}
# own eks and aws resourses with terraform #