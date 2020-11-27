# Using Terraform to create VMs from Snapshots or Images.

## Intro

This repo assumes that you have some basic knowledge of Terraform. There are some great 'how to' guides that Terraform publish; the 30mins of time spent to learn the basics will be well worth the effort. Check them out at [learn.hashicorp.com](https://learn.hashicorp.com/terraform#getting-started)

This repo is meant to be an example of what you can do with Terraform. It is not officially supported by Qlik IT and we will not accept tickets on it. Having said that we will help if we have time.

If you see anything that needs improving please feel free to submit a pull request. The more people that contribute, the better we can make these scripts.

Lastly please make sure you comply with Qlik's Security Policies when you deploy using these scripts. Responsibility for being compliant belongs with you, don't assume the scripts are perfect. If anything looks off, destroy the provision and reach out for help.

### General Notes

* The login credentials for these VMs will be the same as the VMs the snapshots or images were created from.
* Please make sure you run Terraform from within the relevant folder for the cloud you are deploying to.
* If you are forking this repo, please make sure that you do not commit your tfstate or tfstate.backup files.
* Make sure that you do not commit any sensitive information. API Keys for example (not that you should be using these in the first place).
* For the sake of ease, we have included all the variables within the main .tf files. The easiest thing to do is to make sure that there is a "default" value on each of the variables. Alternatively you can use a seperate variable file.

### Notes on Azure

 * Azure supports snapshots for both Linux and Windows VMs.
 * You will need a pre-configured Resource Group for the VM.
 * You will need a pre-configured VNet
 
 ### Notes on AWS
 
 * This is currently a work in progress. Please bear with us.
