CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := zeebe-tasklist
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init:
	helm init --client-only

setup: init
	helm repo add jenkins-x http://chartmuseum.jenkins-x.io
	#helm repo add releases ${CHART_REPO}

build: clean setup
	helm dependency build zeebe-tasklist
	helm lint zeebe-tasklist

install: clean build
	helm upgrade ${NAME} zeebe-tasklist --install

upgrade: clean build
	helm upgrade ${NAME} zeebe-tasklist --install

delete:
	helm delete --purge ${NAME} zeebe-tasklist

clean:
	rm -rf zeebe-tasklist/charts
	rm -rf zeebe-tasklist/${NAME}*.tgz
	rm -rf zeebe-tasklist/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" zeebe-tasklist/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" zeebe-tasklist/Chart.yaml
else
	exit -1
endif
	helm package zeebe-tasklist
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
	jx step changelog  --verbose --version $(VERSION) 
