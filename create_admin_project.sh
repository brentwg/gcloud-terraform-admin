#!/usr/bin/env bash

# ------------------------------------------------------------------------
# This script creates an Admin Project for a Terraform service account
# in order to keep the sources needed for managing a project separate from
# the actual projects.
#
# Based on the following tutorial:
#     Managing GCP Projects with Terraform
#     https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
#
# Brent Gawryluik
# 2018-02-06
# 2018-02-07
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


# -------------------------------------------------------
# Create a the project and link it to the billing account
# -------------------------------------------------------
echo ""
echo "Creating Terraform admin project and linking it to the billing acct..."
gcloud projects create ${TF_ADMIN} \
  --organization ${TF_VAR_org_id} \
  --set-as-default

gcloud beta billing projects link ${TF_ADMIN} \
  --billing-account ${TF_VAR_billing_account}

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "DEBUG"
  echo "gcloud projects list"
  gcloud projects list
  echo ""
  echo "gcloud beta billing projects list --billing-account ${TF_VAR_billing_account}"
  gcloud beta billing projects list --billing-account ${TF_VAR_billing_account}
fi


# --------------------------------------------------------------------------
# Create the service account in the Terraform admin project and download the 
# JSON credentials
# --------------------------------------------------------------------------
echo ""
echo "Creating service account and getting JSON credentials..."
gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account"

gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "DEBUG"
  echo "gcloud iam service-accounts list"
  gcloud iam service-accounts list
  echo ""
  echo "gcloud iam service-accounts keys list \ "
  echo "  --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com"
  gcloud iam service-accounts keys list \
    --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com
fi


# -------------------------------------------------------------------------
# Grant the service account permission to view the Admin Project and manage 
# Cloud Storage
# -------------------------------------------------------------------------
echo ""
echo "Granting service account permissions..."

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/viewer

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/storage.admin


# ----------------------------------------------------------------------------
# Any actions that Terraform performs require that the API be enabled to do so.
# Enable necessary APIs here
# ----------------------------------------------------------------------------
echo ""
echo "Enabling specified APIs..."
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "DEBUG"
  echo "gcloud services list"
  gcloud services list
fi


# --------------------------------------------------------------------------
# Grant the service account permission to create projects and assign billing 
# accounts
# --------------------------------------------------------------------------
echo ""
echo "Granting service account extra permissions..."
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectCreator

gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/billing.user


# ------------------------------------
# Set up remote state in Cloud Storage
# ------------------------------------
echo ""
echo "Setting up remote state in Cloud Storage..."
gsutil mb -p ${TF_ADMIN} gs://${TF_ADMIN}

if [ "${DEBUG}" = true ]; then
  echo ""
  echo "DEBUG"
  echo "gsutil ls"
  gsutil ls
fi

echo ""
echo "END OF SCRIPT"
