provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}vpc"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}igw"
    }
  )
}

resource "aws_subnet" "public" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index+1}.0/24"
  availability_zone = count.index % 2 == 0 ? var.az[0] : var.az[1]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}public${count.index+1}"
    }
  )
}

resource "aws_subnet" "private" {
  count = 4
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index+3}.0/24"
  availability_zone = count.index % 2 == 0 ? var.az[0] : var.az[1]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}private${count.index+1}"
    }
  )
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[1].id

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}nat"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}eip"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}public"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}private"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public.*.id)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private.*.id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}