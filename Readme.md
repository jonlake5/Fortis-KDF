# Usage

## Install terraform in cloudshell

```
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
ln -s ~/.tfenv/bin ~/bin
echo 'PATH=$PATH:~/bin' >> ~/.bash_profile
export PATH=$PATH:~/bin
tfenv install
tfenv use 1.10.3
```

## Get the terraform source code

```
cd /tmp
git clone https://github.com/jonlake5/Fortis-KDF.git
```

## Copy the terraform.tfvars file to each directory

```
cd /tmp/Fortis-KDF
xargs -n 1 cp -v example.terraform.tfvars <<<"CloudTrailToKDF/terraform.tfvars GuardDutyToKDF/terraform.tfvars SecurityHubToKDF/terraform.tfvars VPCToKDF/terraform.tfvars"
```

## Enter each directory and edit the terraform.tfvars with the appropriate information and run terraform

### SecurityHub

```
cd /tmp/Fortis-KDF/SecurityHubToKDF
nano terraform.tfvars
```

Make the requried changes to the file, save it, and run the terraform script.

```
terraform init
terraform apply
```

### Guard Duty

```
cd /tmp/Fortis-KDF/GuardDutyToKDF
nano terraform.tfvars
```

Make the requried changes to the file, save it, and run the terraform script.

```
terraform init
terraform apply
```

### CloudTrail

```
cd /tmp/Fortis-KDF/CloudTrailToKDF
nano terraform.tfvars
```

Make the requried changes to the file, save it, and run the terraform script.

```
terraform init
terraform apply
```

This doesn't automatically setup a cloud trail to push logs to cloud watch, mainly because the customer may have an existing cloud trail they want to use.

The CloudTrailToKDF terraform outputs a CloudTrail Role and a CloudWatchLogGroup. After this is created, configure or create a CloudTrail to send to the CloudWatch log group that was output in terraform using the role that was output. It should be called CloudTrailToCloudWatch.

### VPC Flow Logs

This has only been tested with VPC flow logs sending to a firehose in the same AWS account. Additional roles or configuration may need to happen to allow sending flow logs to a firehose in different accounts.

```
cd /tmp/Fortis-KDF/VPCToKDF
nano terraform.tfvars
```

Make the requried changes to the file, save it, and run the terraform script.

```
terraform init
terraform apply
```

This doesn't automatically setup vpc flow logs to push to firehose. Go to each VPC you want flow logs for, configure and send flow logs to the firehose using the output role and output firehose.

When creating the VPC Flow Logs, under Log record format, it is recommended to pull all fields. Choose Custom format, then under Log Format>Select an Attribute, tick the top box that says Standard Attributes.

## Backup Terraform State (Optional)

You can zip up the Terraform State to persistent storage or the /tmp directory and download it to your machine, so it can be deleted later. Persistent storage is available indefinitely as long as the cloud shell in that region is activated every 120 days or sooner.
[AWS Cloudshell Persistent Storage](https://docs.aws.amazon.com/cloudshell/latest/userguide/limits.html#persistent-storage-limitations)

This will gzip the terraform directory and put it in persistent storage.

```
tar -cvzf ~/Fortis-KDF-Terraform-State.tar.gz -C /tmp Fortis-KDF
```

To restore the terraform directory, unzip it to /tmp

```
tar -zxvf ~/Fortis-KDF-Terraform-State.tar.gz -C /tmp
```

If there isn't enough persistent storage in /home to store the zip file (~409MB), the gzip file can be created on /tmp and downloaded via CloudShell. /tmp is not persistent storage and all data will be removed when the shell session closes.

```
tar -cvzf /tmp/Fortis-KDF-Terraform-State.tar.gz /tmp/Fortis-KDF
```

Download the file from cloudshell (this may take some time to start the download)

Actions>Download File

```
/tmp/Fortis-KDF-Terraform-State.tar.gz
```

or

```
/home/cloudshell-user/Fortis-KDF-Terraform-State.tar.gz
```
