resource "aws_s3_bucket" "original_images" {
  bucket        = "${terraform.workspace}-s3-image-optimization-originals"
  force_destroy = terraform.workspace == "production" ? false : true
}

resource "aws_s3_bucket_acl" "original_images_acl" {
  bucket = aws_s3_bucket.original_images.id
  acl    = "public-read"
}

resource "aws_s3_bucket" "optimized_images" {
  bucket        = "${terraform.workspace}-s3-image-optimization-optimized"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "optimized_images_acl" {
  bucket = aws_s3_bucket.optimized_images.id
  acl    = "public-read"
}
