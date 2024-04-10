resource "aws_ssm_parameter" "foo" {
  name  = "foo"
  type  = "String"
  value = "barr"
}

resource "aws_cloudformation_stack" "example" {
  name = "example-stack"
  template_body = file("AWS-test.yaml")

  # Additional configuration options, if needed
}
