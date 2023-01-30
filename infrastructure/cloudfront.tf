resource "aws_cloudfront_distribution" "distribution" {
  enabled     = true
  price_class = "PriceClass_All"

  origin {
    origin_id   = "optimized_images_bucket"
    domain_name = aws_s3_bucket.optimized_images.bucket_regional_domain_name
  }

  origin {
    origin_id = "image_optimizer_lambda"
    domain_name = trimsuffix(
      trimprefix(
        aws_lambda_function_url.image_optimizer_lambda_public_url.function_url,
      "https://"),
    "/")

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2", "TLSv1.1", "TLSv1", "SSLv3"]
    }
  }

  origin_group {
    origin_id = "origin_group"

    failover_criteria {
      status_codes = [404]
    }

    member {
      origin_id = "optimized_images_bucket"
    }

    member {
      origin_id = "image_optimizer_lambda"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "origin_group"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Accept"]
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.function.arn
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_function" "function" {
  name    = "${terraform.workspace}-s3-image-optimization-url-rewriter"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("../dist/url-rewriter-cf-function.js")
}
