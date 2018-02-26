FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y apt-transport-https python python-pip openssl curl wget git unzip

# Install Azure CLI.
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > \
      /etc/apt/sources.list.d/azure-cli.list && \
    apt-key adv --keyserver packages.microsoft.com \
      --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 && \
    apt-get update && \
    apt-get install -y azure-cli && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI.
RUN pip install awscli --upgrade

# Install Terraform.
RUN TF_VERSION="0.11.3"; \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    unzip terraform_${TF_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TF_VERSION}_linux_amd64.zip
