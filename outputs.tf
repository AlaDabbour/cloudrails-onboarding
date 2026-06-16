# The 6 values the customer copies into the CloudRails registration form. Five map 1:1 to the
# TenancyLinkRequest fields (user_ocid, tenancy_ocid, oci_region, fingerprint, private_key_pem);
# tenancy_name is the bonus capture (cross-checked against get_tenancy at link time).

output "user_ocid" {
  value       = oci_identity_user.svc.id
  description = "Paste into CloudRails: User OCID."
}

output "tenancy_ocid" {
  value       = var.tenancy_ocid
  description = "Paste into CloudRails: Tenancy OCID."
}

output "region" {
  value       = var.region
  description = "Paste into CloudRails: Home region."
}

output "fingerprint" {
  value       = oci_identity_api_key.k.fingerprint
  description = "Paste into CloudRails: API key fingerprint."
}

output "tenancy_name" {
  value       = data.oci_identity_tenancy.this.name
  description = "Your OCI tenancy name (non-secret)."
}

output "private_key_pem" {
  value       = tls_private_key.api.private_key_pem
  sensitive   = true # Resource Manager masks it; reveal then copy into CloudRails (handled no-log).
  description = "Paste into CloudRails: API private key (PEM). Secret — reveal, copy once, do not share."
}
