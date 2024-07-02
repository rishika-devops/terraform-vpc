resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = merge(
    var.vpc_tags,
    var.common_tags,
    {
        Name = local.name
    }
  )
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.igw_tags,
    var.common_tags,
    {
        Name = local.name
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets_cidr[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags , 
    var.public_subnets_tags ,
    {
      Name = "${local.name}-public-${local.az_names[count.index]}"
    }

  )
}
resource "aws_subnet" "private" {
  count = length(var.private_subnets_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets_cidr[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge(
    var.common_tags , 
    var.private_subnets_tags ,
    {
      Name = "${local.name}-private-${local.az_names[count.index]}"
    }

  )
}
resource "aws_subnet" "database" {
  count = length(var.database_subnets_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnets_cidr[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge(
    var.common_tags , 
    var.database_subnets_tags ,
    {
      Name = "${local.name}-database-${local.az_names[count.index]}"
    }

  )
}
resource "aws_db_subnet_group" "default" {
  name       =  "${local.name}"
  subnet_ids = aws_subnet.database[*].id
  tags = {
    Name ="${local.name}"
  }
}
resource "aws_eip" "eip" {
  domain           = "vpc"
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
  tags = merge(
    var.common_tags, 
    var.nat_gateway_tags,
    {
      Name = "${local.name}"
    }
  )
  
 # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tags,
    var.public_route_table_tags,
    {
    Name = "${local.name}-public"
  }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tags,
    var.private_route_table_tags,
    {
    Name = "${local.name}-private"
  }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.common_tags,
    var.database_route_table_tags,
    {
    Name = "${local.name}-database"
  }
  )
}

resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}
resource "aws_route" "private_route" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}
resource "aws_route" "database_route" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "database" {
  count = length(var.database_subnets_cidr)
  subnet_id      = element(aws_subnet.database[*].id, count.index)
  route_table_id = aws_route_table.database.id
}
resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_required ?  1 : 0 
  peer_vpc_id   = var.acceptor_vpc_id == "" ?  data.aws_vpc.default.id : var.acceptor_vpc_id
  vpc_id        = aws_vpc.main.id
  auto_accept   = var.acceptor_vpc_id == "" ?  true : false

  tags = merge(
    var.common_tags , 
    var.vpc_peering_tags,
    {
      Name = "${local.name}"
    }
  )
  }
  resource "aws_route" "acceptor" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ?  1 : 0
  route_table_id            = data.aws_route_table.default.id
  destination_cidr_block    = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}
resource "aws_route" "public_peering" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ?  1 : 0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}
resource "aws_route" "private_peering" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ?  1 : 0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}
resource "aws_route" "database_peering" {
  count = var.is_peering_required && var.acceptor_vpc_id == "" ?  1 : 0
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}