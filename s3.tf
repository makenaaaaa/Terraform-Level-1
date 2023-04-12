resource "aws_s3_bucket" "b" {
  bucket = "makenatest20230406"
  acl    = "public-read"

  // static website hosting
  website {
    index_document = "index.html"
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

// upload index.html
resource "aws_s3_bucket_object" "file_upload" {
  bucket       = aws_s3_bucket.b.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  acl          = "public-read"
}