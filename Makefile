################################################################################
# Meteor Deployment Makefile v.0.0.1 (07-08-2016)
# GitHub: https://github.com/jgontrum/make-meteor
# Author: Johannes Gontrum
#
# Tested for Ubuntu 16.04.1 and Debian 8.5
################################################################################
# LOCAL
## Name of the app
APP=mySuperApp

## Local build path
BUILD_PATH=/tmp/build/$(APP)

################################################################################
# DEPLOYMENT
## Target hostname
REMOTE=live.mysuperapp.com

## Path on the remote machine to copy the meteor app to
REMOTE_PATH=~/$(APP)

## The linux distribution that is running on the server.
## Possible values: ubuntu, debian
REMOTE_SYSTEM=debian

## Name of the system, like 'xenial' for Ubuntu or 'jessie' for Debian.
REMOTE_SYSTEM_VERSION=jessie

## Setup a MongoDB container. If set to false, you should provide your own.
REMOTE_SETUP_MONGO=true

## SHH config for this server
SSH_KEY=~/.ssh/id_rsa
SSH_USER=root

## Choose a tag from here https://hub.docker.com/r/library/mongo/tags/
MONGO_TAG=latest

## Choose a tag from here https://hub.docker.com/r/meteorhacks/meteord/tags/
METEOR_TAG=latest

################################################################################
# ENV
ENV_ROOT_URL=http://$(REMOTE)
ENV_PORT=80
ENV_DATABASE=$(APP)
ENV_MONGO_PORT=27017
ENV_MONGO_URL=mongodb://localhost:$(ENV_MONGO_PORT)
ENV_CLUSTER_WORKERS_COUNT=auto
ENV_MOBILE_DDP_URL=$(ENV_ROOT_URL):$(ENV_PORT)
ENV_MOBILE_ROOT_URL=$(ENV_ROOT_URL):$(ENV_PORT)

# You can specify other environmental variables that will be passed to the
# container for the app.
# The syntax is: '-e VAR1=value1 -e VAR2=value2' etc
OTHER_APP_SETTINGS=

################################################################################
# COMMANDS
SSH=ssh -i $(SSH_KEY) -oStrictHostKeyChecking=no $(SSH_USER)@$(REMOTE)
SCP=scp -i $(SSH_KEY) -oStrictHostKeyChecking=no

# Leave this empty, if you do not use '$(SUDO)'
SUDO=sudo

################################################################################

all:
	@echo "Meteor Deployment Tool for $(APP)"
	@echo "------------------------------------------------"
	@echo "make build         Build the app locally."
	@echo "make deploy        Build and deploy on a server."
	@echo "make remote_setup  Initially setup the server."
	@echo "make clean         Clean temporaty Meteor files."
	@echo ""
	@echo "Please not that 'remote_setup' must be called"
	@echo "before the deployment process."


build: clean $(BUILD_PATH)
	@echo "[$(APP)] Building the Meteor app..."
	meteor build $(BUILD_PATH) --server=$(REMOTE):$(ENV_PORT)

$(BUILD_PATH):
	@mkdir -p $(BUILD_PATH)

deploy: build remote_upload remote_app_stop remote_app_start
	@echo "[$(APP)] Deployment complete."

remote_upload:
	@echo "[$(APP)] Uploading the compiled backup to the remote machine..."
	@$(SSH) 'mkdir -p $(REMOTE_PATH)'
	@$(SCP) $(BUILD_PATH)/$(APP).tar.gz $(SSH_USER)@$(REMOTE):$(REMOTE_PATH)/

# Setup docker depending on the system running on the server
remote_docker_setup:
ifeq ($(REMOTE_SYSTEM),ubuntu)
	@echo "[$(APP)] Starting the initial Docker setup on an Ubuntu machine..."
	@$(SSH) '$(SUDO) apt-get update && $(SUDO) apt-get -y install apt-transport-https ca-certificates && $(SUDO) apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D'
	@$(SSH) '$(SUDO) echo "deb https://apt.dockerproject.org/repo ubuntu-$(REMOTE_SYSTEM_VERSION) main" > /etc/apt/sources.list.d/docker.list'
	@$(SSH) '$(SUDO) apt-get update && $(SUDO) apt-get -y install linux-image-extra-$$(uname -r) docker-engine'
else
ifeq ($(REMOTE_SYSTEM),debian)
	@echo "[$(APP)] Starting the initial Docker setup on a Debian machine..."
	@$(SSH) '$(SUDO) apt-get update && $(SUDO) apt-get -y install apt-transport-https ca-certificates && $(SUDO) apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D'
	@$(SSH) '$(SUDO) echo "deb https://apt.dockerproject.org/repo debian-$(REMOTE_SYSTEM_VERSION) main" > /etc/apt/sources.list.d/docker.list'
	@$(SSH) '$(SUDO) apt-get update && $(SUDO) apt-get -y install docker-engine'
endif
endif

# Start the docker service
remote_docker_start:
	@$(SSH) '$(SUDO) service docker start'
	@echo "[$(APP)] Docker started on the remote machine."

# Download a Docker image for MongoDB.
# See: https://hub.docker.com/r/library/mongo/
remote_mongo_setup:
ifeq ($(REMOTE_SETUP_MONGO),true)
	@echo "[$(APP)] Setting up MongoDB on the remote machine."
	@$(SSH) 'docker pull mongo:$(MONGO_TAG) > /dev/null'
endif

# Start the mongo container
remote_mongo_start:
ifeq ($(REMOTE_SETUP_MONGO),true)
	@$(SSH) 'docker run --name mongo -p 127.0.0.1:27017:27017 -d mongo > /dev/null'
	@echo "[$(APP)] MongoDB started on the remote machine."
endif

# Stop the mongo container
remote_mongo_stop:
ifeq ($(REMOTE_SETUP_MONGO),true)
	@$(SSH) 'docker stop mongo > /dev/null; docker rm mongo > /dev/null'
	@echo "[$(APP)] MongoDB stopped on the remote machine."
endif

remote_mongo_restart: remote_mongo_stop remote_mongo_start

# Download a Docker image for Meteor.
remote_app_setup:
	@echo "[$(APP)] Setting up Meteor on the remote machine..."
	@$(SSH) 'docker pull meteorhacks/meteord:$(METEOR_TAG) > /dev/null'

# Start the actual meter app
remote_app_start:
	@echo "[$(APP)] Starting the app in a Docker container..."
	@$(SSH) 'docker run --name $(APP) -d -v $(REMOTE_PATH):/bundle --net="host" -e ROOT_URL=$(ENV_ROOT_URL) -e MONGO_URL=$(ENV_MONGO_URL)/$(ENV_DATABASE) -e PORT=$(ENV_PORT) -e CLUSTER_WORKERS_COUNT=$(ENV_CLUSTER_WORKERS_COUNT) -e MOBILE_DDP_URL=$(ENV_MOBILE_DDP_URL) -e MOBILE_ROOT_URL=$(ENV_MOBILE_ROOT_URL) $(OTHER_APP_SETTINGS) meteorhacks/meteord > /dev/null'
	@echo "[$(APP)] The app is running now on $(REMOTE):$(ENV_PORT)."

# Stop the app
remote_app_stop:
	@$(SSH) 'docker stop $(APP) > /dev/null; docker rm $(APP) > /dev/null 2>/dev/null; true' 2> /dev/null
	@echo "[$(APP)] App stopped on the remote machine."

remote_app_restart: remote_app_stop remote_app_start

# Install docker, start the service and setup a MongoDB container
remote_setup: remote_docker_setup remote_docker_start remote_mongo_setup remote_app_setup remote_mongo_start
	@echo "[$(APP)] Initial Setup complete."

clean:
	@rm -rf $(BUILD_PATH)
	@rm -rf .meteor/local/bundler-cache
	@rm -rf .meteor/local/cordova-build
	@rm -rf .meteor/local/isopacks
	@rm -rf .meteor/local/plugin-cache
