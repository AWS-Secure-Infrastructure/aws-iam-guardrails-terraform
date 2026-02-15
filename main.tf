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

############################################
# Developer Role
############################################

data "aws_iam_policy_document" "developer_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "developer_role" {
  name               = "${var.project_name}-developer-role"
  assume_role_policy = data.aws_iam_policy_document.developer_assume_role.json

  tags = local.common_tags
}

############################################
# Scoped EC2 Policy
############################################

data "aws_iam_policy_document" "developer_ec2_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances"
    ]

    resources = [
      aws_instance.scoped_instance.arn
    ]
  }
}

resource "aws_iam_policy" "developer_ec2_policy" {
  name   = "${var.project_name}-developer-ec2-policy"
  policy = data.aws_iam_policy_document.developer_ec2_policy.json
}


resource "aws_instance" "scoped_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2"
  })
}

resource "aws_iam_role_policy_attachment" "developer_attach" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.developer_ec2_policy.arn
}

############################################
# Guardrail Explicit Deny Policy
############################################

data "aws_iam_policy_document" "guardrail_deny_policy" {
  statement {
    effect = "Deny"

    actions = [
      "iam:CreateUser",
      "iam:DeleteUser",
      "iam:AttachUserPolicy",
      "iam:DetachUserPolicy",
      "iam:PutUserPolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "guardrail_deny_policy" {
  name   = "${var.project_name}-guardrail-deny"
  policy = data.aws_iam_policy_document.guardrail_deny_policy.json
}

resource "aws_iam_role_policy_attachment" "developer_guardrail_attach" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.guardrail_deny_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_guardrail_attach" {
  role       = aws_iam_role.s3_reader_role.name
  policy_arn = aws_iam_policy.guardrail_deny_policy.arn
}
