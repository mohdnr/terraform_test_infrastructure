resource "aws_cloudfront_distribution" "function_url_test" {
  enabled     = true
  price_class = "PriceClass_200"

  origin {
    domain_name = split("/", aws_lambda_function_url.function_url_test.function_url)[2]
    origin_id   = aws_lambda_function_url.function_url_test.function_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    target_origin_id       = aws_lambda_function_url.function_url_test.function_name
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["CA"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
