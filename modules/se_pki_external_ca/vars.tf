variable "ica_1_csr_output_file" {
  description = "File to write the CSR to"
  type        = string
  default     = "./csr/Test_Org_v1_ICA1_v1.csr"
}

variable "ica_1_cacert_file" {
  type        = string
  default     = "./cacerts/test_org_v1_ica1_v1.crt"
  description = "The file that contains the signed ca cert by the external root ca"
}

variable "ica_1_mount_path" {
  type    = string
  default = "ica1"
}

variable "ica_1_mount_max_lease_ttl" {
  type    = number
  default = 94608000
}

variable "ica_1_mount_default_lease_ttl" {
  type    = number
  default = 3600
}

variable "ica_1_csr_common_name" {
  type    = string
  default = "my common name."
}

variable "ica_1_csr_key_type" {
  type    = string
  default = "rsa"
}

variable "ica_1_csr_key_bits" {
  type    = string
  default = "2048"
}

variable "ica_1_csr_ou" {
  type    = string
  default = "test org"
}

variable "ica_1_csr_organization" {
  type    = string
  default = "test"
}

variable "ica_1_csr_country" {
  type    = string
  default = "DE"
}

variable "ica_1_csr_locality" {
  type    = string
  default = "Düsseldorf"
}

variable "ica_1_csr_province" {
  type    = string
  default = "NRW"
}

variable "ica_2_mount_path" {
  type    = string
  default = "ica2"
}

variable "ica_2_mount_max_lease_ttl" {
  type    = number
  default = 31536000
}

variable "ica_2_mount_default_lease_ttl" {
  type    = number
  default = 3600
}

variable "ica_2_csr_common_name" {
  type    = string
  default = "my common name."
}

variable "ica_2_csr_key_type" {
  type    = string
  default = "rsa"
}

variable "ica_2_csr_key_bits" {
  type    = string
  default = "2048"
}

variable "ica_2_csr_ou" {
  type    = string
  default = "test org"
}

variable "ica_2_csr_organization" {
  type    = string
  default = "test"
}

variable "ica_2_csr_country" {
  type    = string
  default = "DE"
}

variable "ica_2_csr_locality" {
  type    = string
  default = "Düsseldorf"
}

variable "ica_2_csr_province" {
  type    = string
  default = "NRW"
}