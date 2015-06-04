# deploy_service
A simple deployment service for static websites.  This receives push webhooks from Github to
`/push` and runs a `deploy.sh` script located in the rep.

## Assumptions

* The repo for deployment has a `deploy.sh` script in the root
* The repositories themselves are responsible for the deployment to s3
* You configure the service environment with AWS credentials which the deployment will rely on
* You trust your repository contributors to not put malicious code into `deploy.sh`
* You have redis available for Sidekiq

## Usage

* Setup your ENV with a `GITHUB_SECRET`
* Create a webhook to post to `http://yourapp.herokuapp.com/push` or wherever with that secret
