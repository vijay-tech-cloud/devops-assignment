terraform{
    required_version = ">= 1.6.0"
    required_providers {
      aws={ source ="hashicorp/aws", version="~> 5.55"}
      kubernetes={source="hashicorp/kubernetes", version="~> 2.32"}
      helm={source = "hashicorp/helm",version = "~> 2.12"}
      http={source = "hashicorp/http", version = "~> 3.4"}
    }
}