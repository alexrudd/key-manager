# key-manager
[S3 backed SSH key management using AuthorizedKeysCommand, Docker and EC2 instance tagging](https://hub.docker.com/r/alexrudd/key-manager/)

---

## Description
A simple way to manage ssh keys across multiple [Amazon Web Service EC2](https://aws.amazon.com/ec2/) instances using arbitrary access group names and authorized_keys files stored in s3.

key-manager works by using the `AuthorizedKeysCommand` to run a dockerized application. The app reads the instance's tags for a csv formatted list of "access groups" and then looks on s3 for the authorized keys for those same access groups.

The AuthorizedKeysCommand is a SSH server config directive that allows for a custom script, which returns public ssh keys, to be run when a client attempts an SSH connection.

The access groups on s3 can be managed using a simple Makefile included in the [s3keys directory](s3keys/Makefile).

---

## Requirements
* Docker installed on the host and the ability to connect to the public docker hub registry
* An s3 bucket with authorized_keys files stored in the layout: **my-bucket/group-name/authorized_keys**
* An IAM instance profile which allows the instance to make **s3:GetObject** and **ec2:DescribeTags** requests
* An sshd_config with an **AuthorizedKeysCommand** directive that runs the key-manager container

For an example of an instance setup to use the key manager see the [test-server.cft](test-server.cft) CloudFormation template.

### S3 Keys Bucket

Create a bucket in which all your public keys are going to be stored. The keys will be split into groups which you can name arbitrarily.

The folder structure of the bucket is very simple; each group gets a folder in the bucket, and each folder has an authorized_keys file:

```
myorg-bucket/
├──frontend-devs/
|   └── authorized_keys
├──backend-devs/
|   └── authorized_keys
└──monitoring/
    └── authorized_keys
```

Each [authorized_keys](http://www.linuxcertif.com/man/5/authorized_keys/#AUTHORIZED_KEYS_FILE_FORMAT_1172h) file contains lines in the format:

```
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAA...EcI+ZKRDjlpJuu4YU= stace@pretend-machine
```

### IAM Instance Profile

The key-manager application relies on [AWS Temporary Security Credentials](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html) to make the describeTags and getObject requests. These are provided by an [IAM Role](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html) attached to an [Instance Profile](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) associated with the instance.

The CloudFormation template does this all automatically, but if you prefer to set this up manually or are using a different deployment tool, here is the IAM profile JSON:

```json
{
    "Statement": [
        {
            "Resource": "arn:aws:s3:::myorg-keys/*",
            "Action": [
                "s3:GetObject"
            ],
            "Effect": "Allow"
        },
        {
            "Resource": "*",
            "Action": [
                "ec2:DescribeTags"
            ],
            "Effect": "Allow"
        }
    ],
    "Version": "2012-10-17"
}
```

(Replace "myorg-keys" with the name of your keys bucket)

### AuthorizedKeysCommand

The AuthorizedKeysCommand is used to run a script which invokes the key-manger docker container and also performs a background docker pull request to ensure the key-manger is up-to-date

/etc/ssh/sshd_config:

```
AuthorizedKeysCommand /root/bin/authorizedkeys-command %u %k %t %f
AuthorizedKeysCommandUser root
PermitRootLogin no
```

/root/bin/authorizedkeys-command:

```bash
#!/bin/bash
docker run --rm alexrudd/key-manager:latest -u=$1 -k=$2 -t=$3 -f=$4 -s3_bucket=myorg-keys -s3_region=eu-west-1
docker pull alexrudd/key-manager:latest 2>&1 >/dev/null &
exit 0
```

### Access Groups

Instances can be added and removed from access groups using [EC2's resource tagging](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html) abilities. Simply add a comma separated list of access groups to your instances using the key value: **access-groups**. key-manager looks up the related access group folders in s3 and combines the authorized_keys files for each group to be used to verify ssh clients.

```json
{
  "key": "access-groups",
  "value": "frontend-devs,monitoring"
}
```

If you'd rather use a different tag key to the default "access-groups", then that can be specified to key-manager using the flag `-group_tag="my-tag"`

---

## Managing Access

Although it's easy enough to manage the s3 access groups manually, I have also included a basic [management Makefile](s3keys/Makefile) which uses aws cli to provide basic functionality for fetching existing groups, creating new groups, adding keys to groups, and syncing local changes with s3:

* `make install_awscli` - installs the aws cli using pip and starts to configuration wizard
* `make fetch_existing bucket=myorg-keys` - downloads all the current access groups stored in your s3 bucket
* `make sync bucket=myorg-keys` - uploads any changes you've made locally to s3 `this will delete any group that exists in s3 but not locally`
* `make create_group group=new-group` - Creates a new group folder with an empty authorized_keys file
* `make add_key group=new-group key="ssh-rsa AAA...E4YU= comment"` - Appends a key to an existing group's authorized_keys file

---

## CloudFormation Example

I've included a [CloudFormation](https://aws.amazon.com/cloudformation/) template which launches a single instance setup to use key-manager. You can then experiment adding tags, creating access groups, and adding/revoking keys.

To launch the instance, go to the CloudFormation dashboard of your AWS account and click on **Create Stack**. Select to 'Upload a template to Amazon S3' and choose the [key-manager-example.cft](key-manager-example.cft) template from your local file system.

Name your stack and populate the template's parameters:

* **AccessGroupsTag** - The initial value of the 'access-groups' instance tag
* **InstanceType** - t2.micro, t2.small, or t2.medium
* **Key** - The SSH key pair used for emergency access to the instance
* **S3Bucket** - The pre-existing s3 bucket which will store your access group keys
* **S3BucketRegion** - The [region](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region) in which your s3 bucket is located
* **Subnet** - The Subnet within the VPC to deploy the instance to
* **TrustedIpBlock** - The CIDR IP block to allow ssh connections from (ssh user is "core")
* **VPC** - The AWS Virtual Private Cloud to deploy this registry to

Once you've filled out the template's parameters, click through to the 'Review' page and and tick the box that acknowledges the template creates IAM resources. Click 'Create' and wait for your stack to finish creating all the template resources and show status: `CREATE_COMPLETE`

Attempt to SSH to the instance using it's IP (from the stack outputs or ec2 intance dashboard) and the username 'core':

```bash
ssh -v -i ~/.ssh/private-key core@<instance-ip>
```

enable verbose debug output to see which keys are accepted/refused

---

## Disclaimer

I created this application to solve the problem of ssh access control on a small scale (~100 instances; <10 developers) and mainly to prove the concept of an idea I had. I make **no claims** as to its fitness for production or large-scale environments, and would advise you to fully understand the the code and various points of failure of the solution before you think of using it yourself.

Saying that, I welcome any suggestions that could make this project safer, faster, and better suited to the problem at hand.

---

## Building

Makefile has been provided for convenience. Uses the Golang docker image to compile the source and dependencies so no local install on Golang is needed.

```
make build
```

## Contributing

Pull requests are welcome. Consider creating an issue to discuss the feature before doing the development work, or just fork and create a pull request.
