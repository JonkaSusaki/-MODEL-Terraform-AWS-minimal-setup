variable "env" {
  type    = string
  default = "test"
}

variable "bucket_names" {
  type    = list(string)
  default = ["perfil", "local", "role"]

}

resource "aws_s3_bucket" "bucket" {
  for_each      = toset(var.bucket_names)
  bucket        = "${var.env}-bakko-${each.key}"
  force_destroy = true
}

# Creation of public access block
resource "aws_s3_bucket_public_access_block" "public_block" {
  for_each = aws_s3_bucket.bucket
  bucket   = each.value.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "allow_public_access" {
  for_each = aws_s3_bucket.bucket

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${each.value.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "policies" {
  for_each   = aws_s3_bucket.bucket
  bucket     = each.value.id
  policy     = data.aws_iam_policy_document.allow_public_access[each.key].json
  depends_on = [aws_s3_bucket_public_access_block.public_block]
}
