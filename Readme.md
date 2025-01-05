# Usage

## Install terraform in cloudshell

```
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
ln -s ~/.tfenv/bin ~/bin
export PATH=$PATH:~/bin
tfenv install
tfenv use 1.10.3
```

## Get the terraform source code

```
git clone https://github.com/jonlake5/Fortis-KDF.git
```

## Copy the terraform.tfvars file to each directory

```
cd ~/Fortis-KDF
xargs -n 1 cp -v example.terraform.tfvars <<<"CloudTrailToKDF/terraform.tfvars GuardDutyToKDF/terraform.tfvars SecurityHubToKDF/terraform.tfvars"
```

## Enter each directory and edit the terraform.tfvars with the appropriate information and run terraform

### SecurityHub

```
cd ~/Fortis-KDF/SecurityHubToKDF
nano terraform.tfvars
```

Make the requried changes to the file, save it, and run the terraform script.

```
terraform init
terraform apply
```

### Guard Duty

```
cd ~/Fortis-KDF/GuardDutyToKDF
nano terraform.tfvars
```

Make the requried changes to the file, save it, and run the terraform script.

```
terraform init
terraform apply
```

### CloudTrail

```
cd ~/Fortis-KDF/CloudTrailToKDF
nano terraform.tfvars
```

Make the requried changes to the file, save it, and run the terraform script.

```
terraform init
terraform apply
```
