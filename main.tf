resource "aws_cloudformation_stack" "Terraform-cloudformation-stack" {
  name = "Terraform-cloudformation-stack"
  template_body = file("AWS-Terraform-Cloudformation.yaml")
}
