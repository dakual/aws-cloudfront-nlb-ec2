resource "aws_vpc" "main" {
  cidr_block = local.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = local.name
    Environment = local.environment
  }
}

resource "aws_subnet" "private" {
  count             = length(local.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.private_subnets, count.index)
  availability_zone = element(local.availability_zones, count.index)
  
  tags = {
    Name        = "${local.name}-private-subnet-${format("%03d", count.index+1)}"
    Environment = local.environment
  }
}

resource "aws_subnet" "public" {
  count                   = length(local.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(local.public_subnets, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name}-public-subnet-${format("%03d", count.index+1)}"
    Environment = local.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name}-igw"
    Environment = local.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${local.name}-routing-table-public"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "main" {
  name        = "${local.name}-sg"
  description = "Allow all"
  vpc_id      = aws_vpc.main.id

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
}

resource "aws_eip" "nat" {
  count = length(local.private_subnets)
  vpc   = true

  tags = {
    Name        = "${local.name}-eip-${format("%03d", count.index+1)}"
    Environment = local.environment
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(local.private_subnets)

  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name        = "${local.name}-nat-${format("%03d", count.index+1)}"
    Environment = local.environment
  }
}

resource "aws_route_table" "private" {
  count  = length(local.private_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.main.*.id, count.index)
  }

  tags = {
    Name        = "${local.name}-routing-table-private-${format("%03d", count.index+1)}"
    Environment = local.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(local.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}