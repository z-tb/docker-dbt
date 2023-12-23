##
#  Generic dockerfile for dbt image building.
#  See README for operational details
##
# build arguments from Makefile
ARG USER_UID
ARG USER_GROUP_GID
ARG USER_GROUP_NAME
ARG USER_NAME
ARG USER_SHELL
ARG USER_HOME


# Top level build args
ARG build_for=linux/amd64

##
# base image (abstract)
##
# Please do not upgrade beyond python3.10.7 currently as dbt-spark does not support
# 3.11py and images do not get made properly
FROM --platform=$build_for python:3.10.7-slim-bullseye as base

ENV USER_UID=$USER_UID
ENV USER_GROUP_GID=$USER_GROUP_GID
ENV USER_GROUP_NAME=$USER_GROUP_NAME
ENV USER_NAME=$USER_NAME
ENV USER_SHELL=$USER_SHELL
ENV USER_HOME=$USER_HOME
# N.B. The refs updated automagically every release via bumpversion
# N.B. dbt-postgres is currently found in the core codebase so a value of dbt-core@<some_version> is correct

# some of these versions may need tweaking over time - these versions are currently current and compatible
ARG dbt_core_ref=dbt-core@v1.7.4
ARG dbt_postgres_ref=dbt-core@v1.7.2
ARG dbt_redshift_ref=dbt-redshift@v1.7.1
ARG dbt_bigquery_ref=dbt-bigquery@v1.7.2
ARG dbt_snowflake_ref=dbt-snowflake@v1.7.1
ARG dbt_spark_ref=dbt-spark@v1.7.1
# special case args
ARG dbt_spark_version=all
ARG dbt_third_party

# System setup
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    git \
    ssh-client \
    software-properties-common \
    make \
    build-essential \
    ca-certificates \
    libpq-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Env vars
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

# Update python
RUN python -m pip install --upgrade pip setuptools wheel --no-cache-dir

# Set docker basics
WORKDIR /usr/app/dbt/
## 
# use bash below 
# ENTRYPOINT ["dbt"]

##
# dbt-core
##
FROM base as dbt-core
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/${dbt_core_ref}#egg=dbt-core&subdirectory=core"

##
# dbt-postgres
##
FROM base as dbt-postgres
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/${dbt_postgres_ref}#egg=dbt-postgres&subdirectory=plugins/postgres"


##
# dbt-redshift
##
FROM base as dbt-redshift
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/${dbt_redshift_ref}#egg=dbt-redshift"


##
# dbt-bigquery
##
FROM base as dbt-bigquery
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/${dbt_bigquery_ref}#egg=dbt-bigquery"


##
# dbt-snowflake
##
FROM base as dbt-snowflake
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/${dbt_snowflake_ref}#egg=dbt-snowflake"

##
# dbt-spark
##
FROM base as dbt-spark
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    python-dev \
    libsasl2-dev \
    gcc \
    unixodbc-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*
RUN python -m pip install --no-cache-dir "git+https://github.com/dbt-labs/${dbt_spark_ref}#egg=dbt-spark[${dbt_spark_version}]"


##
# dbt-third-party
##
FROM dbt-core as dbt-third-party
RUN python -m pip install --no-cache-dir "${dbt_third_party}"

##
# dbt-all
##
FROM base as dbt-all
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    python-dev \
    libsasl2-dev \
    gcc \
    unixodbc-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*
  RUN python -m pip install --no-cache "git+https://github.com/dbt-labs/${dbt_redshift_ref}#egg=dbt-redshift"
  RUN python -m pip install --no-cache "git+https://github.com/dbt-labs/${dbt_bigquery_ref}#egg=dbt-bigquery"
  RUN python -m pip install --no-cache "git+https://github.com/dbt-labs/${dbt_snowflake_ref}#egg=dbt-snowflake"
  RUN python -m pip install --no-cache "git+https://github.com/dbt-labs/${dbt_spark_ref}#egg=dbt-spark[${dbt_spark_version}]"
  RUN python -m pip install --no-cache "git+https://github.com/dbt-labs/${dbt_postgres_ref}#egg=dbt-postgres&subdirectory=plugins/postgres"


# create a user account, non-root, of the user running the build
#   user gets supplementary sudo group membership for testing/installing additional software 
#   look into docker secrets for managing API keys or other sensitive data. ARGS can be discovered via `docker history`
ARG USER_UID
ARG USER_GROUP_GID
ARG USER_GROUP_NAME
ARG USER_NAME
ARG USER_SHELL
ARG USER_HOME

ENV USER_UID=$USER_UID
ENV USER_GROUP_GID=$USER_GROUP_GID
ENV USER_GROUP_NAME=$USER_GROUP_NAME
ENV USER_NAME=$USER_NAME
ENV USER_SHELL=$USER_SHELL
ENV USER_HOME=$USER_HOME

# Copy custom bash.bashrc additions into the image
COPY etc/bashrc-addition /tmp/

# append bash custom code to /etc/bash.bashrc
RUN cat /tmp/bashrc-addition >> /etc/bash.bashrc && \
    rm /tmp/bashrc-addition 

# add some extra utilities
RUN apt-get update && \
apt-get install sudo \
    net-tools \
    lsb-release \
    curl \
    gnupg \
    wget \
    vim \
    nano \
    zsh \
    git -y


# use Posix attributes provided by the environment to clone a user into the docker container. This allows for compatible access on the $HOME
# directory and /app directories, when mounted
RUN groupadd -g $USER_GROUP_GID $USER_GROUP_NAME
RUN useradd -u ${USER_UID} -g ${USER_GROUP_GID} -G sudo -m -s ${USER_SHELL} ${USER_NAME} -d ${USER_HOME}

# with %sudo, you need to use 'newgrp' after login for some reason, so use the USERNAME here instead
RUN echo "${USER_NAME} ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudo-users

# install hashicorp repo and terraform - nice if you AWS resources to provision in your workflow
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt update &&  apt install -y terraform

# lsb-release is needed by Terraform, but causes problems with Python modules
RUN apt purge lsb-release -y && apt autoremove -y

# switch to non-root build user for shell
USER ${USER_NAME}

# Command to run when the container starts
CMD ["/bin/bash"]
