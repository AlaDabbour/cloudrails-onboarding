# CloudRails OCI onboarding — Resource Manager "Launch Stack" template (v1).
#
# Domains-first (locked decision): ONE template. Group/user/membership are created with the
# legacy/compat `oci_identity_*` resources (no resource-type branching for legacy vs domains), and
# the POLICY group reference is domain-qualified via `domain_name` (default "Default"). Rare
# pre-domains tenancies use the manual runbook (docs/REAL_TENANCY_ACTIVATION.md), not this stack.
#
# Resource Manager auto-populates `tenancy_ocid` and `region` from the customer's session — the
# customer supplies nothing here unless their identity domain is not "Default".

variable "tenancy_ocid" {
  type        = string
  description = "Injected by Resource Manager from the stack's tenancy context."
}

variable "region" {
  type        = string
  description = "Injected by Resource Manager from the stack's region context."
}

variable "domain_name" {
  type        = string
  default     = "Default"
  description = "Your OCI identity domain. Leave as Default unless your tenancy uses multiple domains."
}
