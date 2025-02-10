## gcsfuse-driver

This is sample for mount Google Cloud Storage bucket as volume mounts in Pods running in Google Kubenertes Engine

> [!NOTE]  
> You need to be a Project Owner or have a Google Cloud credentials with Kubernetes Engine Admin, Service Account Admin, Service Account User, Storage Admin permissions

### Tools required

* Google Cloud CLI
* Kubectl
* Kustomize
* Terraform

You can deploy a GKE Cluster running `terraform init && terraform plan && terraform apply` under `terraform/` folder

### Service Accounts configuration for working
You need to create a Kubernetes service account and a Google Service Account with permissions to your bucket

- Create Kubernetes Service Account
This will be used to authenticate your Pods with Google Cloud Storage API
```shel
kubectl create serviceaccount gcs-fuse-sa --namespace default
```

- Create Google Cloud Service Account
This will be used to grant permissions to Google Cloud Storage
```shell
gcloud iam service-accounts create gcs-fuse-gsa \
  --project=YOUR_GCP_PROJECT \
  --description="GCS Fuse Service Account for GKE" \
  --display-name="GCS Fuse GSA"
```

- Grant Storage Permissions to your Google Cloud Service Account
For testing purposes `storage.objectAdmin` permissions is given but you can grant the necessary IAM roles:
```shell
gcloud projects add-iam-policy-binding YOUR_GCP_PROJECT \
  --member="serviceAccount:gcs-fuse-gsa@YOUR_GCP_PROJECT.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

- Enable Workfload Identity for your Kubernetes Service account
Due GKE cluster is provisioned using Workload Identity, this allow to your Kubernetes Service Account impersonate Google Cloud Service Account
```shell
gcloud iam service-accounts add-iam-policy-binding \
  gcs-fuse-gsa@YOUR_GCP_PROJECT.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member="serviceAccount:YOUR_GCP_PROJECT.svc.id.goog[default/gcs-fuse-sa]"
```

- Annotate your Kubernetes Service Account
This link your Kubernetes Service Account with the Google Cloud Service Account in GKE Cluster
```shell
kubectl annotate serviceaccount gcs-fuse-sa \
  iam.gke.io/gcp-service-account=gcs-fuse-gsa@YOUR_GCP_PROJECT.iam.gserviceaccount.com \
  --namespace default
```

### Deploy your Pod
Before run any command against GKE Cluster, retrieve credential using the following command. This append credentials to auth with GKE Cluster into your kubeconfig file
```shell
gcloud container clusters get-credentials YOUR_GKE_CLUSTER_NAME --region us-central1 --project YOUR_GCP_PROJECT
```

Now, you can enter in `app/` folder and run the following command to deploy a sample pod with access to Google Cloud Storage Bucket
```shell
kustomize build . | kubectl apply -f -
```


