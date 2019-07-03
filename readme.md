

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Google Cloud OCR Demo

**By Lee Boonstra, Customer Engineer @ Google Cloud.**

## File Server OCR demo

A common use case for every business, is the digitalization of documents.
Scanned Documents as PDF, JPG, TIFF. To get text from these documents or images,
and process it, we can make use of the OCR detection of the Vision API.
An architecture could look like this diagram:

![alt text](https://github.com/savelee/kube-django-ng/blob/master/images/fileananalytics-architecture.png "Architecture")

This demo, showcases a dummy ML portal.
It exists of the following containers:

* Web Front-end - An Angular app (**front-end** folder)
* FileServer - A Node JS app (**fileserver** folder) with Google Cloud ML integrations

**Disclaimer: This example is made by Lee Boonstra. Written code can be used as a baseline, it's not meant for production usage.**

**Copyright 2018 Google LLC. This software is provided as-is, without warranty or representation for any use or purpose. Your use of it is subject to your agreements with Google.**  

### Automatic Setup on Google Cloud Platform:

Guided one click installation from Google Cloud Shell. No client tooling required.

### Manual Setup / Run Locally

#### Setup Google Cloud

1.  Download and install the [Google Cloud
    SDK](https://cloud.google.com/sdk/docs/), which includes the
    [gcloud](https://cloud.google.com/sdk/gcloud/) command-line tool.

2. Open the Google Cloud Console: http://console.cloud.google.com

3. Make sure a Billing Account is setup & linked. (Select Billing in Main Menu)

4.  Create a [new Google Cloud Platform project from the Cloud
    Console](https://console.cloud.google.com/project) or use an existing one.

    Click the + icon in the top bar.
    Enter an unique project name. For example: *yourname-examples*.
    It will take a few minutes till everything is ready.

5. Initialize the Cloud SDK:
    

        $ gcloud init
        2 (Create a new configuration)
        yourname-examples
        (login)
        list
        #number-of-choice
        y

6. Install Kubectl: `gcloud components install kubectl`

#### Authentication

Authentication is typically done through `Application Default Credentials`,
which means you do not have to change the code to authenticate as long as
your environment has credentials. You have a few options for setting up
authentication:

1. When running locally, use the `Google Cloud SDK`

        gcloud auth application-default login


    Note that this command generates credentials for client libraries. To authenticate the CLI itself, use:
    
        gcloud auth login

1. You can create a `Service Account key file`. This file can be used to
   authenticate to Google Cloud Platform services from any environment. To use
   the file, set the ``GOOGLE_APPLICATION_CREDENTIALS`` environment variable to
   the path to the key file, for example:

        export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service_account.json

* [Application Default Credentials]( https://cloud.google.com/docs/authentication#getting_credentials_for_server-centric_flow)
* [Additional scopes](https://cloud.google.com/compute/docs/authentication#using)
* [Service Account key file](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatinganaccount)

### Install Dependencies

1. Install [Node](https://nodejs.org/en/download/) and [npm](https://www.npmjs.com/get-npm) if you do not already have them.

2. Install [Angular CLI](http://cli.angular.io) - 
`npm install -g @angular-cli`

### Enable the APIs

1. Navigate to the Cloud Console: http://console.cloud.google.com

1. Click on **APIs & Services > Dashboard**

1. Click on **Enable APIs & Services**

1. Enable the following APIS:

* BigQuery API
* Cloud Functions API
* Cloud Pub/Sub API
* Kubernetes Engine
* !!!! Cloud Natural Language API !!!!
* !!!! Cloud Data Loss Protection API !!!!
* Cloud Vision API
* !!!! Cloud Translation API !!!!
* !!!! Cloud Auto ML API !!!!

Or via gcloud:

```
gcloud services enable \
  bigquery-json.googleapis.com \
  cloudfunctions.googleapis.com \
  language.googleapis.com \
  pubsub.googleapis.com \
  container.googleapis.com \
  dlp.googleapis.com \
  dialogflow.googleapis.com \
  vision.googleapis.com \
  automl.googleapis.com \
  translate.googleapis.com \
  cloudbuild.googleapis.com \
  sourcerepo.googleapis.com \
  cloudtrace.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com
```

### Setup Service Account

1. Download the Service Account Key

2. Open http://console.cloud.google.com, and navigate to *APIs & Services > Credentials*.

3. Click **Create Credentials**

4. Select **Dialogflow Integrations**

5. Give it the name: *master.json*,  - select for now Project Owner (in production, you might want to fine tune this on least privaliges)

6. Select **JSON**

7. **Create**

8. Download the key, and store it somewhere on your hard drive, and remember the path.

### Setup Storage Bucket

1. Choose in the left hand menu: **Storage**

2. Click **Create Bucket**

3. Give the bucket a unique name, for example: `myname-ocrproject`

4. Choose **Regional**

5. Set a **location** (for example: `europe-west4`)

6. Click **Create**

## Run the code locally

### Start Client Container

Run on the command-line:

```
cd front-end
npm install
ng serve
```

The Front-end can be reached via http://localhost:4200

### Start FileServer Container

In case you want to run this for the first time:

1. Rename the file from the command-line, and edit:

   ```
   cd ../fileserver/
   npm install
   mv env.txt .env
   nano .env
   ```

2. Modify the code:

   ```
    GCLOUD_PROJECT=<PROJECT NAME>
    GOOGLE_APPLICATION_CREDENTIALS=<LOCATION OF YOUR SERVICE ACCOUNT FILE>
    GCLOUD_STORAGE_BUCKET=<NAME_OF_MY_STORAGE_BUCKET>
    TOPIC=file-content
    DATASET=fileanalytics
    TABLE=fileresults
   ```

3. Then run on the command-line:

   ```
   node app.js
   ```

### Setup Cloud Functions

1. Click **Create Function**

2. Name: **fileanalytics**

3. Select Trigger: **Cloud Pub/Sub**

4. Choose topic: **file-content**

5. Runtime: Node JS 8 (beta)

6. Paste the contents of *cloudfunctions/filestorage/fileanalytics/index.js* into the **index.js** textarea

7. Paste the contents of *cloudfunctions/filestorage/fileanalytics/package.json* into the **package.json** textarea (tab)

8. The function to execute is: **subscribe**

9. Set the following environment variables:

```
DATASET=fileanalytics
TABLE=fileresults
```

1. Click **Create**

1. Click **Create Function**

1. Name: **pdfcontents**

1. Select Trigger: **Cloud Storage**

1. Choose bucket: **myname-ocrproject**

1. Runtime: Node JS 8 (beta)

1. Paste the contents of *cloudfunctions/filestorage/pdfcontents/index.js* into the **index.js** textarea

1. Paste the contents of *cloudfunctions/filestorage/pdfcontents/package.json* into the **package.json** textarea (tab)

1. The function to execute is: **onFileStorage**

1. Set the following environment variables:

```
TOPIC=file-content
GCLOUD_STORAGE_BUCKET = myname-ocrproject
```
1. Click **Create**

### Fileserver Demo flow:

1. In the front-end website, navigate to the **Scanner** tab

2. Upload, PDF, TIFF or JPEG files. (See the *testfiles/* folder for example files)

3. After the upload process, have a look into the Cloud Storage bucket **myname-ocrproject**,
you should see the uploaded asset, as well a JSON representation retrieved through the DOCUMENT DETECTION of the Vision API.

1. Navigate to https://bigquery.cloud.google.com and query the fileresults table, to get the insights:

`SELECT * from `fileanalytics.fileresults` where PATH filename LIMIT 10`


## Deploy your code to GKE with Cloud Builder

1. Create a GKE Cluster:

    `gcloud container clusters create mlportal --region europe-west4-a --num-nodes 1 --enable-autoscaling --min-nodes 1 --max-nodes 4`

    (when you already have a cluster, and you get the error **The connection to the server localhost:8080 was refused - did you specify the right host or port?**, type: `gcloud container clusters get-credentials "mlportal" --zone europe-west4-a`)

2. Set your **PROJECT_ID** and **GCLOUD_STORAGE_BUCKET** variables, which points to your GCP project id. For example:

    `export PROJECT_ID=leeboonstra-blogdemos`
    `export GCLOUD_STORAGE_BUCKET=leeboonstra-ocrproject`

3. Navigate to the root of this repository.

4. Create a secret from your service account **master.json** key

    `kubectl create configmap fileserver-config --from-literal "GCLOUD_PROJECT=${PROJECT_ID}" --from-literal "TOPIC=file-content" --from-literal "DATASET=fileanalytics" --from-literal "TABLE=fileresults" --from-literal "GCLOUD_STORAGE_BUCKET=${GCLOUD_STORAGE_BUCKET}"`
    `kubectl create secret generic credentials --from-file=master.json`

5. Fix paths to your images of the **-deployment.yaml** & **setup** files (in the cloudbuilder folder) to match the container names in your Container Registry.

6. When you setup your cluster for the first time, you can run this command from the root directory:

    `gcloud builds submit --config cloudbuilder/setup.yaml`

7. In case you want to re-deploy individual containers, run the following build scripts:

   `gcloud builds submit --config cloudbuilder/fileserver.yaml`

   `gcloud builds submit --config cloudbuilder/front-end.yaml`

8. To delete deployments use:

   `kubectl delete deployment front-end`

9. To deploy another deployment:

   `kubectl apply -f cloudbuilder/front-end-deployment.yaml`

   `kubectl apply -f cloudbuilder/fileserver-deployment.yaml`


10. Now setup the services and ingress loadbalancer:

    `kubectl apply -f cloudbuilder/ingress.yaml`

    *NOTE: The important thing here is specifying the type of the Service as NodePort . This allocates a high port on each node in the cluster which will proxy requests to the Service.
    Google’s Load Balancer performs health checks on the associated backend service. The service must return a status of 200. If it does not, the load balancer marks the instance as unhealthy and does not send it any traffic until the health check shows that it is healthy again.*
