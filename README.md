# CloudRails — OCI onboarding (Launch Stack)

One-click, **read-only** onboarding for [CloudRails](https://cloudrails.io) FinOps on Oracle Cloud
Infrastructure. Applying this stack in your own tenancy via OCI Resource Manager creates a read-only
group, a dedicated service user, a read policy, and an API key — then prints the values you paste
into CloudRails. CloudRails never gets write access.

## What it creates

- `oci_identity_group` — `cloudrails-readers`
- `oci_identity_user` — `cloudrails-service` (API-key only, no console password)
- `oci_identity_user_group_membership`
- `oci_identity_policy` — tenancy-wide **read** (usage/cost, metrics, inspect resources, FOCUS export)
- `tls_private_key` + `oci_identity_api_key` — an RSA-2048 keypair generated in-stack; only the
  **public** half is uploaded to OCI

## Outputs (paste into CloudRails)

`user_ocid`, `tenancy_ocid`, `region`, `fingerprint`, `tenancy_name`, and `private_key_pem`
(the only **sensitive** output — Resource Manager masks it; reveal and copy it once).

## Prerequisite

The user who applies the stack needs **manage**-Identity rights in the tenancy (a tenancy
administrator) to create the group/user/policy. A read-only user cannot run it — same as any
cloud one-click setup.

## Identity domains

One template. The group/user/membership use the standard `oci_identity_*` resources (which work
against the **Default** identity domain); only the policy's group reference is domain-qualified via
the `domain_name` variable (default `Default`). Set `domain_name` only if your tenancy uses a
non-Default identity domain.

## Releases

The Launch Stack URL points at the immutable release asset for a given template version (e.g.
`onboarding-v1`). Resource Manager downloads that zip directly.
