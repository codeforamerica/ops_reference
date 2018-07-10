# To initialize a backend for Terraform state
Create a file called `development` which contains your Amazon access key id and secret access key. An example template is provided at `backend-config.example`.
These backends will be environment specific, so name them accordingly.
`terraform init -backend-config=./development`

# Provide variables for provisioning
Define a secrets file with Amazon credentials that have access to provisioning resources. An example is provided at secrets.example.

# To preview changes to infrastructure
`terraform plan -var-file=varfile -var-file=secrets`

# To deploy
Set up a virtualenv for Python
`sudo easy_install pip`
`pip install virtualenv`
