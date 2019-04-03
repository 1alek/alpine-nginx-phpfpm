PROJECT=alpine-nginx-phpfpm
DESCRIPTION="Alpine Linux with Nginx + PHP-FPM 7.2 + LOGZ (for yii2)"
NAMESPACE=aleksu

WEBPORT=80
LOGZPORT=1234
ERRORS=0

VERSION=$(shell cat .version)
PREFIX=$(shell date +"%Y%m%d%H%M")-$(shell whoami)

LANG=en_US.UTF-8

CR=\033[0;91m
CG=\033[0;92m
CY=\033[0;93m
CB=\033[0;94m
CP=\033[0;95m
CC=\033[0;96m
CW=\033[00m

all: help

commit: ## Commit changes to git
	@printf "${CG}>>>>>>>>>>>>>> COMMITING CHANGES >>>>>>>>>>>>>>>>>>>>>>>>> ${CW} \n"
	git add -A .
	git commit -m "commit-$(PREFIX)"
	git push origin master
	@printf "${CG}<<<<<<<<<<<<<< DONE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ${CW} \n"

release: ## Make next version and push to git
	@printf "${CG}>>>>>>>>>>>>>> RELEASING NEW VERSION >>>>>>>>>>>>>>>>>>>>> ${CW} \n"
	@printf "${CG}>> Releasing version: ${CY}$(VERSION)${CW} \n"
	git tag release-$(VERSION)
	git push origin tag release-$(VERSION) master:release
	$(eval NEXTVERSION := $(shell awk -F '.' '{build=$$3+1} END {print $$1"."$$2"."build}' .version))
	@printf "${CG}>> Setting next release version: ${CY}$(NEXTVERSION) ${CW} \n"
	echo $(NEXTVERSION) > .version
	git add -A .
	git commit -m "commit-$(PREFIX)"
	git push origin master
	@printf "${CG}<<<<<<<<<<<<<< DONE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ${CW} \n"

images: ## Build Docker images
	@printf "${CG}>>>>>>>>>>>>>> BUILDING DOCKER IMAGE >>>>>>>>>>>>>>>>>>>>>>>>>>> ${CW} \n"
	@docker build --rm -t $(NAMESPACE)/$(PROJECT):$(VERSION) -f ./Dockerfile .
	@docker tag $(NAMESPACE)/$(PROJECT):$(VERSION) $(REGISTRY)/$(NAMESPACE)/$(PROJECT):latest
	@printf "${CG}>>>>>>>>>>>>>> CLEANING EMPTY DOCKER IMAGES >>>>>>>>>>>>>>>>>>>> ${CW} \n"
	@docker image prune -f
	@printf "${CG}<<<<<<<<<<<<<< DONE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ${CW} \n"

push: ## Push Docker images to Registry
	@printf "${CG}>>>>>>>>>>>>>> PUSHING IMAGES TO REGISTRY >>>>>>>>>>>>>>>>>>>>>> ${CW} \n"
	@docker push $(NAMESPACE)/$(PROJECT):latest
	@printf "${CG}<<<<<<<<<<<<<< DONE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ${CW} \n"

clean: ## Clean docker images
	@printf "${CG}>> Stopping running containers...${CW} \n"
	docker ps | grep $(PROJECT) | awk '{print $1}' | xargs -r docker stop
	@printf "${CG}>> Deleting containers...${CW} \n"
	docker ps -a | grep $(PROJECT) | awk '{print $1}' | xargs -r docker rm -f
	@printf "${CG}>> Deleting images...${CW} \n"
	docker images | grep $(PROJECT) | awk '{print $1}'| xargs -r docker rmi -f
	@printf "${CG}>> Done.${CW} \n"

help: ## Show Help
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.SILENT: ;
.PHONY: all
.SHELLFLAGS = -c
.ONESHELL: ;
.NOTPARALLEL: ;