terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = { source = "oracle/oci" }
    tls = { source = "hashicorp/tls" } # generates the API keypair inside the stack
  }
}

# Resource Manager injects the signer (the stack runs as the customer's session / RM principal),
# so the provider block carries no credentials.
provider "oci" {}

# Domain-qualified group reference for the policy statements (e.g. 'Default'/'cloudrails-readers').
# The group/user resources below use the legacy/compat oci_identity_* types (work against the
# Default domain); ONLY the policy statement qualifies the group with the domain name.
locals {
  group_name = "cloudrails-readers"
  grp        = "'${var.domain_name}'/'${local.group_name}'"
}

# Read-only group.
resource "oci_identity_group" "readers" {
  compartment_id = var.tenancy_ocid
  name           = local.group_name
  description    = "CloudRails read-only FinOps access"
}

# Dedicated service user (API key only — no console password).
resource "oci_identity_user" "svc" {
  compartment_id = var.tenancy_ocid
  name           = "cloudrails-service"
  description    = "CloudRails read-only service user (API key only)"
}

resource "oci_identity_user_group_membership" "m" {
  user_id  = oci_identity_user.svc.id
  group_id = oci_identity_group.readers.id
}

# Tenancy-wide read policy. Statements are domain-qualified via local.grp.
resource "oci_identity_policy" "readers" {
  compartment_id = var.tenancy_ocid # tenancy-root → tenancy-wide read
  name           = "cloudrails-readers-policy"
  description    = "CloudRails read-only FinOps grants"
  statements = [
    # --- CONFIRMED LIVE against the real tenancy (docs/REAL_TENANCY_ACTIVATION.md) ---
    "Allow group ${local.grp} to read usage-report in tenancy",     # Usage API (cost) — singular, CONFIRMED
    "Allow group ${local.grp} to read metrics in tenancy",          # Monitoring (utilization / idle)
    "Allow group ${local.grp} to inspect all-resources in tenancy", # Resource Search + list_* (inventory)

    # --- FOCUS / Cost-&-Usage Reports: Oracle writes these to an ORACLE-OWNED bucket in the
    #     `reporting` tenancy (bucket name = the tenancy OCID), NOT the customer's tenancy — so this
    #     is a CROSS-TENANCY endorse, not a local Allow. `reporting` is Oracle's fixed cost-report
    #     tenancy (same OCID for every customer). Harmless until the customer enables Cost & Usage
    #     Reports (the bucket simply 404s). ---
    "Define tenancy reporting as ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbiifq7rk7w2g4ofunijsuuq",
    "Endorse group ${local.grp} to read objects in tenancy reporting",

    # --- PLURAL alias `usage-reports`: NOT a recognized OCI resource-type (Part B verification,
    #     2026-06-16). OCI validates resource-types at CreatePolicy, so an ACTIVE plural statement
    #     would make this whole stack's Apply fail. Kept here, DISABLED, as a drop-candidate; enable
    #     ONLY if a manage-identity sandbox spike (scripts/verify_oci_plural_usage_report_grant.py)
    #     proves OCI accepts it. ---
    # "Allow group ${local.grp} to read usage-reports in tenancy",

    # --- OPTIONAL / UNCONFIRMED: commitment (OneSubscription). Add only after run_commitment_ingest
    #     names the real resource-type in a ServiceError (see docs/REAL_TENANCY_ACTIVATION.md,
    #     "Commitment / OneSubscription grants"). ---
    # "Allow group ${local.grp} to read osub-subscription in tenancy",
    # "Allow group ${local.grp} to read osub-commitment  in tenancy",
    # "Allow group ${local.grp} to read osub-usage        in tenancy",
  ]
}

# API signing keypair — generated in-stack. Only the PUBLIC half is uploaded to OCI; the PRIVATE
# half is exposed as a sensitive output the customer copies into the CloudRails registration form.
resource "tls_private_key" "api" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "oci_identity_api_key" "k" {
  user_id   = oci_identity_user.svc.id
  key_value = tls_private_key.api.public_key_pem # OCI stores the public key, returns the fingerprint
}

# Real OCI tenancy name — primary capture point for onboarding (also covered by get_tenancy at link).
data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}
