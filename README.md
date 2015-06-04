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

## How this works

The service receives a push from Github.  It verifies the request is legitimate via the shared
secret.  If verified, it ensures the repository is owned by a whitelisted owner.

If that succeeds, it kicks off a Sidekiq background worker.  The worker currently clones the
repository to a temporary directory, thereby creating a fresh copy everytime.  This may change to
pull strategy when it becomes cumbersome, currently it is not and keeps things simpler.

Once the repository is cloned, the worker invokes a clean Bundler environment, changes into the
repository directory, and invokes the `deploy.sh` script found at the root.

## Example Deploy Script

Here's a small example deploy script for middleman to s3:

```shell
#!/bin/sh

set -e

bundle
bundle exec middleman build
bundle exec middleman s3_sync
```
