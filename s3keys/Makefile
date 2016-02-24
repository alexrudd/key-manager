bucket=mybucket
region=eu-west-1
group=""
key=""

install_awscli:
	@echo "installing aws cli..."
	@pip install awscli
	@if [ ! -f ~/.aws/credentials ] ; then echo aws cli is not configured!; aws configure ; fi

has_awscli:
	@hash aws 2>/dev/null || { echo >&2 "AWS CLI not installed. Run 'make install_awscli'"; exit 1; }
	@[ -e ~/.aws/credentials ] || { echo >&2 "AWS CLI is not configured. Run 'make install_awscli'"; exit 1; }

fetch_existing: has_awscli
	aws s3 sync --region ${region} s3://${bucket}/ .

sync: has_awscli
	@echo ""
	@echo "=============================================="
	@echo "!!This command can permanently delete groups!!"
	@echo "=============================================="
	@echo ""
	@echo "Any groups that exists in s3 but doesn't"
	@echo "exist locally will be deleted. Consider "
	@echo "running 'make fetch_existing' before making"
	@echo "any changes."
	@echo ""
	@echo "You have 10sec to cancel this action (Ctrl+C)"
	@sleep 1 && echo -n "."
	@sleep 1 && echo -n "."
	@sleep 1 && echo -n "."
	@sleep 1 && echo -n "."
	@sleep 1 && echo -n "#"
	@sleep 1 && echo -n "#"
	@sleep 1 && echo -n "#"
	@sleep 1 && echo -n "!"
	@sleep 1 && echo -n "!"
	@sleep 1 && echo -n "!"
	@echo ""
	aws s3 sync --region ${region} --exclude "Makefile" --exclude ".gitignore" . s3://${bucket}/ --delete

create_group:
	@if [ -z "${group}" ]; then \
		echo "usage: make create_group group=my-new-group"; \
		exit 1; \
	else \
		mkdir ${group}; \
		touch ${group}/authorized_keys; \
	fi
	@echo "Group created!"
	@echo "Run 'make add_key group=${group} key=\"ssh-rsa AAAAB3N...UH0= key-comment\"' to add a new key"

add_key:
	@if [ -z "${group}" || -z "${key}" ]; then \
		echo "usage: make add_key group=my-new-group key=\"ssh-rsa AAAAB3N...UH0= key-comment\""; \
		exit 1; \
	else \
		echo ${key} >> ${group}/authorized_keys; \
	fi
	@echo "Key added!"
	@echo "Run 'make sync' to update the groups on s3"
