FROM ubuntu:xenial

ENV PATH="/root/.terraform.d/plugins/linux_amd64/:${PATH}"
ENV KUBECTL_VERSION "v1.14.3"

RUN apt-get update && \
    apt-get install -y apt-transport-https python3 python3-pip openssl curl wget git unzip \
        software-properties-common wget curl openssh-client openvpn sudo

# python3 executable is called "python3" on xenial, let's symlink it to a more common name just in case
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Azure CLI.
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > \
      /etc/apt/sources.list.d/azure-cli.list && \
    curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y azure-cli

# Upgrade pip
RUN pip3 install --upgrade pip

# Install jq
RUN apt-get install -y jq

# Install AWS CLI.
RUN pip install awscli --upgrade

# Install Terraform.
RUN TF_VERSION="0.12.16"; \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    unzip terraform_${TF_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TF_VERSION}_linux_amd64.zip

# Install ansible
RUN pip install ansible --upgrade

# Install yq
RUN pip install yq --upgrade

# Install Go 1.11.
RUN add-apt-repository --yes ppa:gophers/archive && \
    apt-get update && \
    apt-get install -y golang-1.11-go && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/lib/go-1.11/bin/go /usr/local/bin/go

# Install ct provider
RUN VERSION=v0.3.2 && \
    mkdir -p /root/.terraform.d/plugins/linux_amd64 && \
    wget https://github.com/poseidon/terraform-provider-ct/releases/download/$VERSION/terraform-provider-ct-$VERSION-linux-amd64.tar.gz && \
    tar xzf terraform-provider-ct-$VERSION-linux-amd64.tar.gz && \
    mv terraform-provider-ct-$VERSION-linux-amd64/terraform-provider-ct ~/.terraform.d/plugins/linux_amd64/terraform-provider-ct

# Build gotemplate provider from source.
RUN export GOPATH="/opt/go" && \
    mkdir -p /root/.terraform.d/plugins/linux_amd64 && \
    mkdir -p ${GOPATH} && \
    go get -u github.com/giantswarm/terraform-provider-gotemplate && \
    ln -sf ${GOPATH}/bin/terraform-provider-gotemplate /root/.terraform.d/plugins/linux_amd64/terraform-provider-gotemplate

# download kubectl
RUN curl -o /usr/local/bin/kubectl  \
    https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# create user with jenkins id
RUN groupadd -g 117 jenkins && useradd -u 113 jenkins -g 117 -G sudo -m

# copy custom terraform providers for jenkins user
RUN cp /root/.terraform.d /home/jenkins/ -R && chown jenkins:jenkins /home/jenkins/.terraform.d -R

# add sudo rules for openvpn for jenkins
RUN echo "jenkins ALL = (root) NOPASSWD: /usr/sbin/openvpn,/usr/bin/pkill" >> /etc/sudoers
