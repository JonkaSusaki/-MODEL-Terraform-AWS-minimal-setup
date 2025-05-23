variable "env" {
  type    = string
  default = "dev"
}

data "aws_iam_policy_document" "allow_public_access" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.name.arn}/*"]
  }
}

resource "aws_s3_bucket" "name" {
  bucket        = "${var.env}-bucket-bakko-1"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.name.id
  policy = data.aws_iam_policy_document.allow_public_access.json

  depends_on = [ aws_s3_bucket_public_access_block.name ]
}

resource "aws_s3_bucket_public_access_block" "name" {
  bucket = aws_s3_bucket.name.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
