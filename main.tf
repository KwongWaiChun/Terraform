resource "google_storage_bucket" "static" {
 name          = "terraform_test-bucket"
 location      = "US"
 storage_class = "STANDARD"

 uniform_bucket_level_access = true
}