# Dockerized dbt Development Environment

This repository contains a Dockerfile and Makefile to simplify the setup and management of a dbt (Data Build Tool) development environment. It's designed to provide a consistent and isolated environment for dbt projects.

The bulk of the Dockerfile was provided by https://docs.getdbt.com/docs/core/docker-install and additional capability was added so the dbt container could be used withing Dev Containers in vscode.  Additional configuration for customizing the bash environment is provided in the `etc/bashrc-addition`` file which is added to the environment at build time.

The Makefile provides targets which will build the Docker container to create a user which matches the user UID and GID group of the user building the container. This is intended to run the container without `root` level permissions and allow R/O access to the home directory of the user running the container. On a windows system, you will not have these same Posix attributes and will need to initialize them with values in the Dockerfile since they will not exist in the windows environment and cannot be passed to Docker during build.

Look over the provided .gitignore and make sure it provides the expected functionality 


Use the `pcol` alias for a fancier colored prompt with git status reporting.

## Prerequisites

Make sure you have Docker installed on your machine. You can download Docker from [https://www.docker.com/get-started](https://www.docker.com/get-started).

## Getting Started

### Build the Docker Image

Build the Docker image using the following command:

```bash
make build
```

This will create a Docker image with the necessary dependencies for dbt.

### Run the Docker Container

Run the Docker container interactively:

```bash
make run
```

For running the container with the `./app` directory mounted, use:

```bash
make runm
```

To mount both the `./app` directory and the user's home directory:

```bash
make runmh
```

### Connecting to the Running Container

If the container is already running, you can connect to it using:

```bash
make connect
```

### Stopping and Cleaning

Stop the running container:

```bash
make stop
```

To stop and remove the container and image:

```bash
make clean
```

### Additional Targets

- **show-variables:** Display variable values used in the Makefile.
- **build_upgrade:** Build the Docker image and upgrade pip packages if implemented in the Dockerfile.

## Customization

You can customize the build by modifying the Dockerfile and adjusting the Makefile variables.

## Contributing

Feel free to contribute to this project by opening issues or creating pull requests.

## License

This project is licensed under the [MIT License](LICENSE).
```
