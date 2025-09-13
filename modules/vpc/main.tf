resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.public_route_table_name
  }
}
 
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public" {
  for_each = { for i, name in var.public_subnet_names : name => i }

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[each.value]
  availability_zone       = data.aws_availability_zones.az.names[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name = each.key
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each      = { for i, name in var.private_route_table_names : name => i }

  vpc_id        = aws_vpc.vpc.id

  tags = {
    Name = each.key
  }
}

resource "aws_subnet" "private" {
  for_each = { for i, name in var.private_subnet_names : name => i }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[each.value]
  availability_zone = data.aws_availability_zones.az.names[each.value]

  tags = {
    Name = each.key
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[var.private_subnet_names[count.index]].id
  route_table_id = aws_route_table.private[var.private_route_table_names[count.index]].id
}

resource "aws_eip" "nat" {
  count = length(var.private_route_table_names)
}

resource "aws_nat_gateway" "nat" {
  count = length(var.private_route_table_names)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.public_subnet_names[count.index]].id

  tags = {
    Name = var.nat_gateway_names[count.index]
  }
}

resource "aws_route" "private" {
  count = length(var.private_route_table_names)

  route_table_id = aws_route_table.private[var.private_route_table_names[count.index]].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id     = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table" "protect" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.protect_route_table_name
  }
}

resource "aws_subnet" "protect" {
  for_each = { for i, name in var.protect_subnet_names : name => i }

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.protect_subnet_cidrs[each.value]
  availability_zone       = data.aws_availability_zones.az.names[each.value]

  tags = {
    Name = each.key
  }
}

resource "aws_route_table_association" "protect" {
  for_each       = aws_subnet.protect

  subnet_id      = each.value.id
  route_table_id = aws_route_table.protect.id
}