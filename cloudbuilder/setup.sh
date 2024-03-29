#!/bin/bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

err() {
  echo "$*" >&2;
}

source ./properties
source ./fileserver/.env

if [ -z "$PROJECT_ID" ]; then
  err "Not running in a GCP project. Please run gcloud config set project $PROJECT_ID."
  exit 1
fi

if [ -z "$CLOUD_BUILD_EMAIL" ]; then
  err "Cloud Build email is empty. Exiting."
  exit 1
fi

bold "Starting the setup process in project $PROJECT_ID..."
bold "Enable APIs..."
gcloud services enable \
  container.googleapis.com \
  bigquery-json.googleapis.com \
  cloudfunctions.googleapis.com \
  pubsub.googleapis.com \
  language.googleapis.com \
  dlp.googleapis.com \
  vision.googleapis.com \
  automl.googleapis.com \
  translate.googleapis.com \
  dialogflow.googleapis.com \
  cloudbuild.googleapis.com \
  sourcerepo.googleapis.com \
  cloudtrace.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com

bold "Creating a service account $SERVICE_ACCOUNT_NAME..."

gcloud iam service-accounts create \
  $SERVICE_ACCOUNT_NAME \
  --display-name $SERVICE_ACCOUNT_NAME

SA_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:$SERVICE_ACCOUNT_NAME" \
  --format='value(email)')
  
if [ -z "$SA_EMAIL" ]; then
  err "Service Account email is empty. Exiting."
  exit 1
fi

bold "Adding policy binding to $SERVICE_ACCOUNT_NAME email: $SA_EMAIL"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/bigquery.dataViewer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/bigquery.jobUser
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/pubsub.editor
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/pubsub.viewer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/storage.objectCreator
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/storage.objectViewer
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/dialogflow.admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/dialogflow.reader
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/clouddebugger.agent
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/errorreporting.admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SA_EMAIL \
  --role roles/logging.logWriter

bold "Creating Bucket..."
gsutil mb -c regional -l europe-west4 $BUCKET_URI

bold "Creating Cloud Functions..."
gcloud functions deploy $CF_FILES \ 
--region=europe-west1 \
--memory=256MB \
--trigger-topic=$TOPIC_FILES
--retry \ 
--runtime=nodejs8 \ 
--source=./cloudfunctions/filestorage/fileanalytics \ 
--stage-bucket=$BUCKET_NAME \ 
--timeout=60s \ 
--entry-point=subscribe \
--update-labels=[DATASET=$DATASET_FILES,TABLE=$TABLE_FILES]] 
gcloud functions deploy $CF_PDF \ 
--region=europe-west1 \
--memory=256MB \
--trigger-bucket=$BUCKET_NAME
--retry \ 
--runtime=nodejs8 \ 
--source=./cloudfunctions/filestorage/pdfcontents \ 
--stage-bucket=$BUCKET_NAME \ 
--timeout=60s \ 
--entry-point=onFileStorage \
--update-labels=[TOPIC=$TOPIC_FILES,GCLOUD_STORAGE_BUCKET=$BUCKET_NAME]] 

bold "Creating cluster..."
gcloud container clusters create $GKE_CLUSTER \ 
    --region $REGION \
    --num-nodes 1 \
    --enable-autoscaling \ 
    --enable-autoupgrade \
    --enable-autorepair \
    --enable-stackdriver-kubernetes \
    --min-nodes 1 \
    --max-nodes 4 \
    --scopes "https://www.googleapis.com/auth/cloud-platform"
gcloud container clusters get-credentials $GKE_CLUSTER --zone $REGION

bold "Install service account secret..."
    
kubectl create configmap fileserver-config \
    --from-literal "GCLOUD_PROJECT=$PROJECT_ID" \
    --from-literal "TOPIC=$TOPIC_FILES" \
    --from-literal "DATASET=$DATASET_FILES" \ 
    --from-literal "TABLE=$TABLE_FILES"  \
    --from-literal "GCLOUD_STORAGE_BUCKET=$BUCKET_NAME" 
kubectl create secret generic credentials --from-file=master.json

bold "Starting deployments..."
gcloud builds submit --config cloudbuilder/setup.yaml
kubectl apply -f cloudbuilder/ingress.yaml

bold "Setup network addresses"
gcloud compute --project=$PROJECT_ID addresses create $GKE_CLUSTER --global --network-tier=PREMIUM

bold "Deployment complete!"