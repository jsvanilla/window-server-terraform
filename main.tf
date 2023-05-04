provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example_vpc"
  }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "example_subnet"
  }
}

resource "aws_security_group" "allow_rdp" {
  name        = "allow_rdp"
  description = "Allow RDP traffic"
  vpc_id      = aws_vpc.example.id # Asocia el grupo de seguridad con la VPC creada anteriormente

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "name" {
  count                       = 3
  ami                         = data.aws_ami.windows_server.id
  associate_public_ip_address = true # si no colocas este parametro, por defecto tus instancias no tendran ip publicas
  instance_type               = "t2.micro"
  key_name                    = "terraform_ec2"
  subnet_id                   = aws_subnet.example.id
  vpc_security_group_ids      = [aws_security_group.allow_rdp.id]

  tags = {
    Name = "terraform_ec2"
  }

  user_data = <<-EOF
    <powershell>
      # Instalación de .NET Framework environment & SQL Server 2019 Developer Edition
      Install-WindowsFeature -Name "NET-Framework-45-Features" -IncludeAllSubFeature
      Install-WindowsFeature -Name "NET-Framework-45-Core"
      [System.Environment]::SetEnvironmentVariable("ACCEPT_EULA", "Y", "Machine")
      Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=866662" -OutFile "SQLServer2019-DEV-x64-ENU.exe"
      Start-Process -FilePath "SQLServer2019-DEV-x64-ENU.exe" -ArgumentList "/Q", "/IACCEPTPYTHONLICENSETERMS", "/IACCEPTROPENLICENSETERMS", "/IACCEPTSQLSERVERLICENSETERMS", "/ACTION=install", "/FEATURES=SQLEngine,FullText,DQ,BC,Conn", "/INSTANCENAME=MSSQLSERVER", "/SECURITYMODE=SQL", "/SAPWD=MyStr0ngP@ssw0rd", "/TCPENABLED=1", "/UPDATEENABLED=False" -Wait
      Remove-Item "SQLServer2019-DEV-x64-ENU.exe"

      # Instalar Node.js
      Invoke-WebRequest -Uri "https://nodejs.org/dist/v14.18.1/node-v14.18.1-x64.msi" -OutFile "node-v14.18.1-x64.msi"
      Start-Process -FilePath "node-v14.18.1-x64.msi" -ArgumentList "/quiet" -Wait
      Remove-Item "node-v14.18.1-x64.msi"

      # Instalar Git
      Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.34.0.windows.1/Git-2.34.0-64-bit.exe" -OutFile "Git-2.34.0-64-bit.exe"
      Start-Process -FilePath "Git-2.34.0-64-bit.exe" -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS", "/NOICONS", "/COMPONENTS=\"icons,ext,ext\\reg\\shellhere,assoc,assoc_sh\"" -Wait
      Remove-Item "Git-2.34.0-64-bit.exe"

      # Clonar el repositorio con la aplicación CRUD Node.js
      git clone https://github.com/jsvanilla/node-sql-server.git C:\\node-sql-server

      # Cambiar al directorio de la aplicación e instalar las dependencias
      Set-Location -Path C:\\node-sql-server
      npm install

      # Iniciar la aplicación Node.js en segundo plano
      Start-Process -FilePath "node" -ArgumentList "app.js" -WindowStyle Hidden
    </powershell>
  EOF
}

output "public_ips" {
  value = [for instance in aws_instance.name : instance.public_ip]
}
