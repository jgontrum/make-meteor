# Make Meteor

Makefile to easily deploy your Meteor app using Docker.

Popular solutions to the automatic deployment of Meteor apps like 'MeteorUP' or the successor 'mupx' are like a black box to me: You hit a button and if you are lucky, your app is deployed in the end. However, I often struggled with problems regarding the deployment of multiple apps on the same server that might even share the same database.

I see this Makefile not as a out-of-the-box solution, but as a starting point if you are not happy with 'mupx' either.

It has been tested on OSX as the source system and current Ubuntu and Debian servers.

## Usage

Set the name of the app (APP), the name of the server (REMOTE) and the os of the server and its version (REMOTE_SYSTEM and REMOTE_SYSTEM_VERSION).

Initial set-up:

```
make remote_setup
```

Deployment

```
make deploy
```

That's it.

## Parameters

A description of the variables in the Makefile

Variable                  | Default Value                         | Description
------------------------- | ------------------------------------- | --------------------------------------------------------------------
**APP**                   | mySuperApp                            | The name of your app. Identifies your Docker container.
BUILD_PATH                | /tmp/build/$(APP)                     | Path to build your app on your computer.
---                       | ---                                   | ---
**REMOTE**                | live.mysuperapp.com                   | The IP or URL of your server.
REMOTE_PATH               | ~/$(APP)                              | Path to upload your app to on the server.
**REMOTE_SYSTEM**         | debian                                | OS of the server. debian or ubuntu
**REMOTE_SYSTEM_VERSION** | jessie                                | The name of the system. Used to download the correct Docker version.
REMOTE_SETUP_MONGO        | true                                  | If true, a container for MongoDB will be started.
SSH_KEY                   | ~/.ssh/id_rsa                         | The path to your SSH key for the SSH / SCP connections.
**SSH_USER**              | root                                  | SSH user (duh!)
MONGO_TAG                 | latest                                | The tag for the MongoDB Docker image
METEOR_TAG                | latest                                | The tag for the Meteor Docker image
---                       | ---                                   | ---
**ENV_ROOT_URL**          | http://$(REMOTE)                      | URL for your app.
**ENV_PORT**              | 80                                    | Port under which your app will be accessible.
ENV_DATABASE              | $(APP)                                | Name of the MongoDB database to use.
ENV_MONGO_PORT            | 27017                                 | Port for MongoDB
ENV_MONGO_URL             | mongodb://localhost:$(ENV_MONGO_PORT) | The whole MongoDB url
ENV_CLUSTER_WORKERS_COUNT | auto                                  | Multithreading for Meteor
ENV_MOBILE_DDP_URL        | $(ENV_ROOT_URL):$(ENV_PORT)           | Fixes connection problems of mobile apps.
ENV_MOBILE_ROOT_URL       | $(ENV_ROOT_URL):$(ENV_PORT)           | Fixes connection problems of mobile apps.
OTHER_APP_SETTINGS        |                                       | Add your own environmental variables here. Syntax: -e VAR=value
---                       | ---                                   | ---
SUDO                      | sudo                                  | Make this empty if you do not want to use sudo.

Most of the values do not have to be changes. The important ones are marked in bold.
