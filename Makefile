IMAGE_NAME 	 	= dbt-test-image
IMAGE_VERSION   = latest
CONTAINER_NAME 	= dbt-test-container
HOST_PATH 	    = ./app
USER_UID 		:= $(shell id -u)
USER_GROUP_GID 	:= $(shell id -g)
USER_GROUP_NAME := $(shell id -gn)
USER_NAME 		:= $(shell id -un)
USER_SHELL 		:= $(shell echo $$SHELL)
USER_HOME 		:= $(shell echo $$HOME)
PIP_UPGRADE		:= "false"

# Make target to echo variable values
show-variables:
	@echo "USER_UID: $(USER_UID)"
	@echo "USER_GROUP_GID: $(USER_GROUP_GID)"
	@echo "USER_GROUP_NAME: $(USER_GROUP_NAME)"
	@echo "USER_NAME: $(USER_NAME)"
	@echo "USER_SHELL: $(USER_SHELL)"
	@echo "USER_HOME: $(USER_HOME)"
	@echo "IMAGE_NAME: $(IMAGE_NAME)"
	@echo "CONTAINER_NAME: $(CONTAINER_NAME)"
	@echo "HOST_PATH: $(HOST_PATH)"

# build with standard settings
build:    
	docker build \
		--build-arg USER_UID=$(USER_UID) \
		--build-arg USER_GROUP_GID=$(USER_GROUP_GID) \
		--build-arg USER_GROUP_NAME=$(USER_GROUP_NAME) \
		--build-arg USER_NAME=$(USER_NAME) \
		--build-arg USER_SHELL=$(USER_SHELL) \
		--build-arg USER_HOME=$(USER_HOME) \
		--build-arg PIP_UPGRADE=$(PIP_UPGRADE) \
		-t $(IMAGE_NAME):${IMAGE_VERSION} -f ./Dockerfile .

# build with no docker cache
rebuild:    
	docker build --no-cache \
		--build-arg USER_UID=$(USER_UID) \
		--build-arg USER_GROUP_GID=$(USER_GROUP_GID) \
		--build-arg USER_GROUP_NAME=$(USER_GROUP_NAME) \
		--build-arg USER_NAME=$(USER_NAME) \
		--build-arg USER_SHELL=$(USER_SHELL) \
		--build-arg USER_HOME=$(USER_HOME) \
		--build-arg PIP_UPGRADE=$(PIP_UPGRADE) \
		-t $(IMAGE_NAME):${IMAGE_VERSION} -f ./Dockerfile .

# upgrade pip pacakges (if implemented in Dockerfile)
build_upgrade:    
	docker build \
		--build-arg USER_UID=$(USER_UID) \
		--build-arg USER_GROUP_GID=$(USER_GROUP_GID) \
		--build-arg USER_GROUP_NAME=$(USER_GROUP_NAME) \
		--build-arg USER_NAME=$(USER_NAME) \
		--build-arg USER_SHELL=$(USER_SHELL) \
		--build-arg USER_HOME=$(USER_HOME) \
		--build-arg PIP_UPGRADE="true" \
		-t $(IMAGE_NAME):${IMAGE_VERSION} -f ./Dockerfile .

# run the container
run:
	docker run -it --rm \
	--user ${USER_UID}:${USER_GROUP_GID}  \
	--name $(CONTAINER_NAME) \
	$(IMAGE_NAME):${IMAGE_VERSION}

# run the container with the app directory in the CWD mounted on /app in the container
runm:
	docker run -it --rm \
	--user ${USER_UID}:${USER_GROUP_GID} \
	--name ${CONTAINER_NAME} \
	--volume ./app:/app/ \
	${IMAGE_NAME}:${IMAGE_VERSION}

# run the container with the app directory in the CWD mounted on /app in the container
# along with $HOME of the user running the container mounted on /mnt/$LOGNAME
runmh:
	docker run -it --rm \
	--user ${USER_UID}:${USER_GROUP_GID} \
	--name ${CONTAINER_NAME} \
	--volume ./app:/app/ \
	--volume /home/${USER_NAME}:/mnt/${USER_NAME}:ro \
	${IMAGE_NAME}:${IMAGE_VERSION}

# assume the container is already running and start a shell in it
connect:
	docker exec -it $(CONTAINER_NAME) /bin/bash

# stop the container
stop:
	docker stop $(CONTAINER_NAME)

# remove the container and image
clean: stop
	docker rm $(CONTAINER_NAME)
	docker rmi $(IMAGE_NAME)

# Display help message
help:
	@echo "Available targets:"
	@echo "  make build       - Build the Docker image"
	@echo "  make run         - Run the Docker container"
	@echo "  make runm        - Run the Docker container with volume mounted app directory"
	@echo "  make runmh       - Run the Docker container with mounted app directory and user's home directory mounted read-only on /mnt/${USER_NAME}"
	@echo "  make connect	  - Connect to the running container"
	@echo "  make stop        - Stop the Docker container"
	@echo "  make clean       - Stop and remove the Docker container, and remove the Docker image"
	@echo "  make help        - Display this help message"
	@echo "  make rebuild     - Build the docker image with --no-cache option"
# vim: set ts=4 sw=4 tw=0 noet :
