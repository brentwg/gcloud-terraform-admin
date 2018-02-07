#!/usr/bin/env bash

# ------------------------------------------------------------------------
# This script deletes the Admin Project for a Terraform service account.
#
# Based on the following tutorial:
#     Managing GCP Projects with Terraform
#     https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
#
# Brent Gawryluik
# 2018-02-06
# ------------------------------------------------------------------------

# ----------------
# Script Variables
# ----------------
OPTIND=1
DEBUG=false
ENV_FILE="gcp.env"


# --------------
# Usage Function
# --------------
function usage() {
  cat << EOF

  Usage: $0 [OPTIONS]

    -d  Enables DEBUG which increases output verbosity

EOF
}


# ------------
# Process ARGS
# ------------
while getopts ":d" opt; do 
  case $opt in
    d)
      DEBUG=true
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done
shift "$((OPTIND-1))"


# -------------------------------
# Source the GCP environment file
# -------------------------------
echo "Sourcing script ENV variables..."
source ./${ENV_FILE}

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "DEBUG"
  echo "TF_VAR_org_id: ${TF_VAR_org_id}"
  echo "TF_VAR_billing_account: ${TF_VAR_billing_account}"
  echo "TF_ADMIN: ${TF_ADMIN}"
  echo "TF_CREDS: ${TF_CREDS}"
fi


# ---------------
# Disable billing
# ---------------
echo ""
echo "Disabling billing (unlinking)"
gcloud beta billing projects unlink ${TF_ADMIN}

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "DEBUG"
  echo "gcloud beta billing projects list --billing-account ${TF_VAR_billing_account}"
  gcloud beta billing projects list --billing-account ${TF_VAR_billing_account}
fi


# ------------------------
# Delete the admin project
# ------------------------
echo ""
echo "Deleting the Terraform admin project..."
gcloud projects delete ${TF_ADMIN}

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "DEBUG"
  echo "gcloud projects list"
  gcloud projects list
fi


# ----------------------------------
# Remove service account permissions
# ----------------------------------
echo ""
echo "Removing service account permissions..."
gcloud organizations remove-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectCreator

gcloud organizations remove-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/billing.user


# --------------------------------
# Remove the JSON credentials file
# --------------------------------
echo ""
echo "Removing the JSON credentials file"
rm -fv ${TF_CREDS}

echo ""
echo "END OF SCRIPT"
