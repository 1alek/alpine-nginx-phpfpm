include .env
export

MAJORVER=$(shell cat .version)
COMMIT=$(shell git rev-list --count HEAD)
VERSION=${MAJORVER}.${COMMIT}
PREFIX=$(shell date +"%Y%m%d%H%M")-$(shell whoami)

CR=\033[0;91m
CG=\033[0;92m
CY=\033[0;93m
CB=\033[0;94m
CP=\033[0;95m
CC=\033[0;96m
CW=\033[0;97m
C0=\033[00m

all: help

commit: ## Commit changes to git
	@printf "${CG}>>>>>>>>>>>>>> COMMITING CHANGES >>>>>>>>>>>>>>>>>>>>>>>>> ${C0} \n"
	git add -A .
	git commit -m "commit-$(VERSION)"
	git push origin master
	@printf "${CG}<<<<<<<<<<<<<< DONE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ${C0} \n"

images: ## Build docker images and upload to Registry
	@printf "${CG}>>>>>>>>>>>>>> BUILDING DOCKER IMAGE >>>>>>>>>>>>>>>>>>>>>>>>>>> ${C0} \n"
	docker build --rm -t $(REGISTRY)/$(NAMESPACE)/$(PROJECT):$(VERSION) -f ./Dockerfile .
	docker tag $(REGISTRY)/$(NAMESPACE)/$(PROJECT):$(VERSION) $(REGISTRY)/$(NAMESPACE)/$(PROJECT):latest
	@printf "${CG}>>>>>>>>>>>>>> PUSHING IMAGES TO REGISTRY >>>>>>>>>>>>>>>>>>>>>> ${C0} \n"
	docker push $(REGISTRY)/$(NAMESPACE)/$(PROJECT):latest
	@printf "${CG}>>>>>>>>>>>>>> CLEANING EMPTY DOCKER IMAGES >>>>>>>>>>>>>>>>>>>> ${C0} \n"
	@docker images -f dangling=true -q | xargs -r docker rmi
	@printf "${CG}<<<<<<<<<<<<<< DONE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ${C0} \n"

clean: ## Stop and Delete all containers and images
	@printf "${CG}>> Stopping running containers...${C0} \n"
	@docker ps | awk '/$(PROJECT)/ {print $$1}' | xargs -r docker stop
	@printf "${CG}>> Deleting containers...${C0} \n"
	@docker ps -a | awk '/$(PROJECT)/ {print $$1}' | xargs -r docker rm -f
	@printf "${CG}>> Deleting images...${C0} \n"
	@docker images | awk '/$(PROJECT)/ {print $$3}'| xargs -r docker rmi -f
	@printf "${CG}>> Done.${C0} \n"

env: ## Show environment variables
	@env

version: ## Show version
	@echo ${VERSION}

help: ## Show this help
	@printf "${CW}NAME${C0}\n      ${CC}$(PROJECT)${C0}\n\n"
	@printf "${CW}DESCRIPTION${C0}\n      ${CC}$(DESCRIPTION)${C0}\n\n"
	@printf "${CW}VERSION${C0}\n      ${CC}${VERSION}${C0}\n\n${CW}OPTIONS${C0}\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "      ${CC}%-20s${C0} %s\n", $$1, $$2}'

.SILENT: ;
.PHONY: all
.SHELLFLAGS = -c
.ONESHELL: ;
.NOTPARALLEL: ;