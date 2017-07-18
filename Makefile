name=key-manager
registry=alexrudd
gitrepo=github.com/alexrudd
tag=2.1
go_ver=1.9

default:
	@echo ""
	@echo "	make build"
	@echo "		compiles the key-manager app and builds the docker image"
	@echo ""
	@echo "	make run"
	@echo "		runs the docker image in the background (stops any existing container)"
	@echo ""
	@echo "	make stop"
	@echo "		stops the running key-manager container"
	@echo ""

run: stop
	docker run \
	--name=${name} \
	-d \
	${registry}/${name}:${tag}

runt:
	docker run \
	--rm \
	-ti \
	${registry}/${name}:${tag} -debug

stop:
	docker rm -f `docker ps -a | grep ${name} | head -n 1 | cut -d ' ' -f 1` || true

build: gofmt gobuild dockbuild

dockbuild:
	[ -e ca-certificates.crt ] || curl -Lsf https://curl.haxx.se/ca/cacert.pem -o ca-certificates.crt
	docker build -t ${registry}/${name}:${tag} .

gofmt:
	# format
	docker run \
	-v `pwd`/key-manager:/go/src/key-manager:Z \
	golang:${go_ver} \
	go fmt ./src/key-manager/...

gobuild:
	# copy src
	mkdir -p _src/${gitrepo}/${name} _pkg _bin
	cp -r key-manager/* _src/${gitrepo}/${name}
	# compile
	docker run \
	-v `pwd`/_pkg:/go/pkg:Z \
	-v `pwd`/_bin:/go/bin:Z \
	-v `pwd`/_src:/go/src:Z \
	-e CGO_ENABLED=0 \
	-e GOOS=linux  \
	golang:${go_ver} \
	go get ./src/${gitrepo}/${name}/...

clean:
	rm -rf _*

pull:
	docker pull ${registry}/${name}:${tag}

push:
	docker push ${registry}/${name}:${tag}

logs:
	@docker logs `docker ps | grep ${name} | head -n 1 | cut -d ' ' -f 1`

logsf:
	@docker logs -f `docker ps | grep ${name} | head -n 1 | cut -d ' ' -f 1`

attach:
	docker exec -ti `docker ps | grep ${name} | head -n 1 | cut -d ' ' -f 1` /bin/sh
