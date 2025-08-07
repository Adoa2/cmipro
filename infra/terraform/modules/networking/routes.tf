# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "Public"
  }
}

# Rutas para subredes privadas
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  # Ruta hacia NAT Gateway (corregida)
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = var.environment == "prod" ? aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id : aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Type = "Private"
  }
  
  depends_on = [aws_nat_gateway.main]
}

# Route Table para Base de Datos (sin salida a Internet)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-${var.environment}-database-rt"
    Type = "Database"
  }
}

# Asociaciones de Route Tables con Subredes
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}