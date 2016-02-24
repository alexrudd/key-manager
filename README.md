# key-manager
s3 backed SSH key management using AuthorizedKeysCommand, Docker and ec2 instance tagging

## Description
A simple way to manage ssh keys across multiple Amazon Web Services EC2 instances using arbitrary access groups and authorized_keys files stored in s3.

## Requirements
* Docker installed on the host and the ability to connect to the public docker hub registry
* An s3 bucket with authorized_keys files stored in the layout: `my-bucket/group-name/authorized_keys`
* An IAM instance profile which allows the instance to make `s3:GetObject` and `ec2:DescribeTags` requests
* An sshd_config with an `AuthorizedKeysCommand` directive that runs the key-manager container

For an example of an instance setup to use the key manager see the [test-server.cft](test-server.cft) CloudFormation template.

## Building

Makefile has been provided for convenience. Uses the Golang docker image to compile the source and dependencies so no local install on Golang is needed.

```
make build
```

## Contributing

Pull requests are welcome. Consider creating an issue to discuss the feature before doing the development work, or just fork and create a pull request.
