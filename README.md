# GCLOUD - Terraform Admin Project

These scripts are used to create and destroy a Terraform Admin Project on Google Cloud Platform (GCP). Using a service account exclusively for Terraform, the Admin project can be used to keep  resources needed for managing Terraform projects separate from the actual projects that are being developed.  

The scripts were developed based on Dan Isla's tutorial, [Managing GCP Projects with Terraform](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform). As per the tutorial, the basic objectives of these scripts are as follows:  
- Create a Terraform Admin Project for the service account  
- Grant Organization-level permissions to the service account  
- Create a remote backend bucket to store the Terraform state file  

## Dependencies  

Basic things you will require:  
- A GCP account (with permission to make organizational-level changes)
- A GCP [organization](https://cloud.google.com/resource-manager/docs/creating-managing-organization#setting-up)
- The Google [Cloud SDK](https://cloud.google.com/sdk/docs/authorizing)  

### GCP Credentials  

To manage GCP credentials, I use a program called `pass`. For more information about `pass` see the following link:  
- [The Standard Unix Password Manager: Pass](https://www.passwordstore.org/)  

The `gcp.env` file queries `pass` and sets environment variables for the following information:  
```
Organization ID
Billing Account ID
Terraform Admin Project ID (must be unique)
Path to GCP credentials JSON file
```

You can find the values for your Organization ID and and your Billing Account ID using the following commands:  
```
gcloud organizations list
gcloud beta billing accounts list
```

## Quickstart

Step 1:  
Modify the gcp.env file to match your own environment. The information you'll need to configure is:  

- TF_VAR_org_id  
- TF_VAR_billing_account  
- TF_ADMIN  
- TF_CREDS  

Step 2:  
To create the Terraform Admin Project, run the following command:  
```
./create_admin_project.sh
```  

(Optional)  
Step 3:  
To delete the Terraform Admin Project (as well as the service account and access keys), run the following command:  
```
./delete_admin_project.sh
```

## GCP Resources  

- GCP Project
- GCP Project-Billing link
- Service Account
- JSON Credentials
- Viewer and Storage Service Account permissions
- Google APIs:  
  - Cloud Resource Manager
  - Cloud Billing
  - IAM
  - Compute Engine
- Service Account permissions to create projects and assign billing accounts
- Storage Cloud bucket (with versioning enabled)
