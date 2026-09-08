resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "${var.project}-${var.env}-vpc"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.project}-${var.env}-igw"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 0)

  tags = {
    Name = "${var.project}-${var.env}-public-subnet-${count.index}"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    "Name" = "${var.project}-${var.env}-public-route-table"
  }
}

resource "aws_route_table_association" "lb" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "main" {
  vpc_id            = aws_vpc.main.id
  availability_mode = "regional"

  tags = {
    Name = "${var.project}-${var.env}-nat"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    "Name" = "${var.project}-${var.env}-private-route-table"
  }
}



resource "aws_route_table_association" "data" {
  subnet_id      = aws_subnet.data_subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app" {
  count          = 2
  subnet_id      = aws_subnet.app_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}


resource "aws_subnet" "app_subnet" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 4)

  tags = {
    Name = "${var.project}-${var.env}-app-subnet-${count.index}"
  }
}

resource "aws_subnet" "data_subnet" {

  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 6)

  tags = {
    Name = "${var.project}-${var.env}-data-subnet"
  }
}

