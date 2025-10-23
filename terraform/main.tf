
# VPC Configuration (creating a Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Public Subnet Configuration
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet"
  }
}

# Private Subnet Configuration
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" 
  tags = {
    Name = "Private Subnet"
  }
}

# IAM Role for EKS Cluster (Required for EKS to operate)
resource "aws_iam_role" "eks_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_eks_cluster" "main" {
  name     = "retail-store-cluster"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_policy_attach,
    aws_subnet.private,
    aws_subnet.public
  ]
}