FROM ubuntu:xenial

ENV PATH="/root/.terraform.d/plugins/linux_amd64/:${PATH}"
ENV KUBECTL_VERSION "v1.14.3"

RUN apt-get update && \
    apt-get install -y apt-transport-https python python-pip openssl curl wget git unzip \
        software-properties-common wget curl openssh-client openvpn sudo

# Install Azure CLI.
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > \
      /etc/apt/sources.list.d/azure-cli.list && \
    curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y azure-cli

# Install AWS CLI.
RUN pip install awscli --upgrade

# Install Terraform.
RUN TF_VERSION="0.12.1"; \
    wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    unzip terraform_${TF_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TF_VERSION}_linux_amd64.zip

# Install Go 1.11.
RUN add-apt-repository --yes ppa:gophers/archive && \
    apt-get update && \
    apt-get install -y golang-1.11-go && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/lib/go-1.11/bin/go /usr/local/bin/go

# Build ct provider from source.
RUN mkdir -p /root/.terraform.d/plugins/linux_amd64 && \
    git clone https://github.com/poseidon/terraform-provider-ct.git && \
    cd terraform-provider-ct && \
    git checkout v0.3.2 && \
    go build && \
    ln -sf terraform-provider-ct /root/.terraform.d/plugins/linux_amd64/terraform-provider-ct

# Build gotemplate provider from source.
RUN export GOPATH="/opt/go" && \
    mkdir -p ${GOPATH} && \
    go get -u github.com/giantswarm/terraform-provider-gotemplate && \
    ln -sf ${GOPATH}/bin/terraform-provider-gotemplate /root/.terraform.d/plugins/linux_amd64/terraform-provider-gotemplate

# download kubectl
RUN curl -o /usr/local/bin/kubectl  \
    https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# create user with jenkins id
RUN groupadd -g 117 jenkins && useradd -u 113 jenkins -g 117 -G sudo -m

# add sudo rules for openvpn for jenkins
RUN echo "jenkins ALL = (root) NOPASSWD: /usr/sbin/openvpn,/usr/bin/pkill" >> /etc/sudoers
