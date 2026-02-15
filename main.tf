############################################
# S3 Bucket (Scoped Resource)
############################################

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "${var.project_name}-secure-bucket-${random_id.suffix.hex}"

  tags = local.common_tags
}

resource "random_id" "suffix" {
  byte_length = 4
}

############################################
# EC2 Instance (Scoped Resource)
############################################

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "scoped_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2"
  })
}
