# Terraform best practices

## Don't push `.terraform` and `.tfstate` files to VCS

The `.terraform` folder is created by `terraform init` which is executed by every user that wishes to use terraform configuration, so it's unique for each user.

The `.tfstate` is a sensitive data and should not be shared publicly (or among the developers). It is much saver to use "remote" backend to store it on a server and to allow multiple developers to collaborate on the same state.

## Use `terraform.tfvars` file only in compositions

Composition is the *final* infrastructure that is composed of many other terraform modules. It is what will be there and *it* is what should be configurated completely. Don't configurate using `terraform.tfvars` the modules themselves. *Their* variables are to be configured by the top-level user of the modules.

## Look into the documentation for the providers in terraform registry

## Don't use terraform provisioners

Provisioners are part of terraform for pragmatic purposes, for extreme edge cases only. The problem is that provisioners are imperative and do not integrate with the other HCL code well, because they can do anything, and terraform won't be able to track it. They may break integrity of the state and are not easy to use. Many providers provide other means for provisioning: for example, the aws provider's `aws_instance`s have `user_data` field that you can set to `file("path/to/script.sh")` to run the script on start.

## Use workspaces if your configurations don't differ much

If your prod and dev configuration are very similar, you can merge them into one and use a concept of a *workspace*. In Terraform CLI a workspace just separates the states of the same configuration, you can think of them as a name for `.tfstate` that will be used to read and write the current state.

The configuration allows for a slight variability between workspaces by using interpolation. For instance, a difference between prod and dev could be the number of instances. The `count` in `aws_instance` could be then `count = "${terraform.workspace == "default" ? 5 : 1}"`

Althogh, you should be cautions when hardcoding the workspace names other than `default`.

## Use outputs.tf to specify useful and interesting information about the infrastructure to the user.

To specify an output, write
```
output "name" {
    value = /* for example */ aws_instance.default.public_ip
}
```

When `terraform apply` completes the outputs will be shown at the bottom of the terminal.
