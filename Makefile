name=key-manager
registry=alexrudd
gitrepo=github.com/alexrudd
tag=1.0
go_ver=1.6

default: run

run: stop
	docker run \
	--name=${name} \
	-d \
	${registry}/${name}:${tag}

runt:
	docker run \
	--rm \
	-ti \
	${registry}/${name}:${tag}

stop:
	docker rm -f `docker ps -a | grep ${name} | head -n 1 | cut -d ' ' -f 1` || true

build: gobuild dockbuild

dockbuild:
	[ -e ca-certificates.crt ] || wget https://curl.haxx.se/ca/cacert.pem -O ca-certificates.crt
	docker build -t ${registry}/${name}:${tag} .

gobuild:
	# copy src
	mkdir -p _src/${gitrepo}/${name}
	cp -r `ls -l | grep '^d' |awk '{ print $$9 }' | grep -vE '^_'` _src/${gitrepo}/${name}
	# compile
	docker run \
	-v `pwd`:/go/src/${gitrepo}/${name} \
	-v `pwd`/_pkg:/go/pkg \
	-v `pwd`/_bin:/go/bin \
	-v `pwd`/_src:/go/src \
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
