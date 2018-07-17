FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y apt-transport-https python python-pip openssl curl wget git unzip \
        software-properties-common

# Install Azure CLI.
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > \
      /etc/apt/sources.list.d/azure-cli.list && \
    curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y azure-cli

# Install AWS CLI.
RUN pip install awscli --upgrade

# Install Terraform.
RUN TF_VERSION="0.12.0"; \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    unzip terraform_${TF_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TF_VERSION}_linux_amd64.zip

# We need to build ct_config terraform provider from sources, because of two things:
# 1. it's still not avaialble in terraform repos [1].
# 2. latest binary release v0.2.1 is too old and does not support passwd groups.
#
# Links:
# 1 - https://github.com/coreos/terraform-provider-ct/issues/21

# Install Go 1.10.
RUN add-apt-repository --yes ppa:gophers/archive && \
    apt-get update && \
    apt-get install -y golang-1.10-go && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/lib/go-1.10/bin/go /usr/local/bin/go

# Build ct_config provider from sources.
RUN export GOPATH="/opt/go" && \
    mkdir -p ${GOPATH} && \
    go get -u github.com/coreos/terraform-provider-ct && \
    ln -sf ${GOPATH}/bin/terraform-provider-ct /bin/terraform-provider-ct
