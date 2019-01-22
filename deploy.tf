module "deploy-eu-west-2" {
  source = "deployment\/cloud-infrastructure\/basic"
  region = "eu-west-2"
}

module "deploy-ap-south-1" {
  source = "deployment\/cloud-infrastructure\/basic"
  region = "ap-south-1"
}
