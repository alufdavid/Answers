provider "aws" {
  region     = "ca-central-1"
  # Use Aws Cli To login (Fetch Creds)
}

# 1. Create an S3 Bucket to Store the Website Files:
# This is where all your website files, such as index.html, will be stored.
resource "aws_s3_bucket" "website_bucket" {
  bucket = "your-unique-name-static-website-2024"  # Replace with a globally unique name for the S3 bucket
}

# 2. Enable Static Website Hosting on the S3 Bucket:
# This tells S3 that it will serve the content as a static website and defines the entry page.
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website_bucket.id  # Link the website configuration to the created S3 bucket

  index_document {
    suffix = "index.html"  # Default page to be served when the website is accessed
  }
}

# Public Access Block: This locks the bucket so no one can mess with it publicly, 
# even by mistake (to ensure the website is served only by CloudFront).
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Set Up a CloudFront Distribution to Serve the Website:
# CloudFront is a CDN (Content Delivery Network) that caches your website globally.
# It will serve your S3 bucket content quickly to users worldwide.
resource "aws_cloudfront_distribution" "website" {
  enabled             = true  # Enable CloudFront distribution
  is_ipv6_enabled     = true  # Enable IPv6 for the distribution
  default_root_object = "index.html"  # Specify the default page to serve

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name  # Link CloudFront to the S3 bucket
    origin_id   = aws_s3_bucket.website_bucket.id  # Unique identifier for the origin

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }
  }

  # Configure caching and behavior of the CloudFront distribution
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]  # Allow only GET and HEAD methods (static files)
    cached_methods         = ["GET", "HEAD"]  # Cache GET and HEAD methods for performance
    target_origin_id       = aws_s3_bucket.website_bucket.id  # CloudFront fetches content from S3
    viewer_protocol_policy = "redirect-to-https"  # Ensure all traffic is served over HTTPS

    forwarded_values {
      query_string = false  # Do not forward query strings (simplifies caching)
      cookies {
        forward = "none"  # Do not forward cookies for better caching
      }
    }

    min_ttl     = 0       # Minimum time-to-live (TTL) for caching
    default_ttl = 3600    # Default TTL for caching (1 hour)
    max_ttl     = 86400   # Maximum TTL for caching (1 day)
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"  # No geo-restrictions, serve globally
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true  # Use CloudFront’s default SSL certificate for HTTPS
  }
}

# 4. Ensure the Bucket Policy Allows CloudFront to Access the Content Securely:
# This allows CloudFront to access the files in the S3 bucket securely.
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website_bucket.id  # Link the policy to the S3 bucket

  policy = jsonencode({
    Version = "2012-10-17",  # Standard IAM policy version
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess",
        Effect    = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.website.iam_arn  # Allow CloudFront access
        },
        Action   = "s3:GetObject",  # Allow CloudFront to get objects from the bucket
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"  # Apply this to all objects in the bucket
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]  # Ensure the public access block is applied before the policy
}

# CloudFront OAI (Origin Access Identity): 
# This is a special helper that CloudFront uses to securely fetch files from the S3 bucket.
resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "OAI for website bucket"  # A description for the CloudFront OAI
}

# Optional: Upload Files to S3: 
# We upload the "index.html" file to the S3 bucket to be served as the homepage.
resource "aws_s3_object" "website_files" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "index.html"  # Path to the local file to upload
  content_type = "text/html"  # Content type for the file
}

# Output the CloudFront Distribution Domain Name:
# This will give the public URL to access the website.
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.website.domain_name  # This is the CloudFront URL for the website
}

# Optional: Output the Bucket Name:
# This gives the name of the S3 bucket, useful for debugging or reference.
output "bucket_name" {
  value = aws_s3_bucket.website_bucket.id  # The name of the created S3 bucket
}
