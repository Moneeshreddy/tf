# modules/vpc/main.tf

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.vpc_tags
}

resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)  
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = merge(var.vpc_tags, {
    "Name" = "public-subnet-${count.index + 1}-${element(data.aws_availability_zones.available.names, count.index)}"
  })
}

resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + local.az_count)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(var.vpc_tags, {
    "Name" = "private-subnet-${count.index + 1}-${element(data.aws_availability_zones.available.names, count.index)}"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = var.igw_tags
}

  resource "aws_nat_gateway" "nat" {
#    count = var.environment == "prod" ? local.az_count : 0 # Create NAT gateways only for prod 
    count = local.az_count
    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id 
    tags = {
      "Name" = "${var.environment}-nat-gateway-${count.index + 1}-${element(data.aws_availability_zones.available.names, count.index)}"
    }
  }

  resource "aws_eip" "nat" {
#    count = var.environment == "prod" ? local.az_count : 0 
    count = local.az_count
    tags = {
      "Name" = "${var.environment}-nat-gateway-ip-${count.index + 1}-${element(data.aws_availability_zones.available.names, count.index)}"
    }
  }

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_default_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_assoc" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_default_route_table.default.id
}

# tag the default route table as public
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  count  = local.az_count
  vpc_id = aws_vpc.main.id

  tags = merge(var.vpc_tags, {
    "Name" = "private-rt-${count.index + 1}-${element(data.aws_availability_zones.available.names, count.index)}"
  })
}

  resource "aws_route" "private_subnet_route" {
#    count                  = var.environment == "prod" ? local.az_count : 0
    count = local.az_count
    route_table_id         = aws_route_table.private[count.index].id
    destination_cidr_block = "0.0.0.0/0"
#    nat_gateway_id         = var.environment == "prod" ? clear.nat[count.index].id : null
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

resource "aws_route_table_association" "private_subnet_assoc" {
  count          = local.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


# API Lambda Security Group
resource "aws_security_group" "lambda-api" {
  name        = "lambda-api"
  vpc_id      = aws_vpc.main.id
}


# Database Security Group
resource "aws_security_group" "docdb-primary" {
  name        = "docdb-primary"
  vpc_id      = aws_vpc.main.id
}


resource "aws_security_group_rule" "api-egress" {
  type = "egress"
  from_port = 27017
  to_port = 27017
  protocol = "tcp"

  description = "Lambda Access to DocumentDB"
  security_group_id = aws_security_group.lambda-api.id
  source_security_group_id = aws_security_group.docdb-primary.id
}

resource "aws_security_group_rule" "api-ingress" {
  type = "ingress"
  from_port = 27017
  to_port = 27017
  protocol = "tcp"

  description = "Lambda Access to DocumentDB"
  security_group_id = aws_security_group.docdb-primary.id
  source_security_group_id = aws_security_group.lambda-api.id
}

resource "aws_security_group_rule" "lambda-https-al" {
  type = "egress"
  from_port = 443
  to_port = 443
  protocol = "tcp"

  description = "lambda https access"
  security_group_id = aws_security_group.lambda-api.id
  cidr_blocks = [ "0.0.0.0/0" ] 
}
