FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y git curl python3 python3-pip gnupg2 nginx postgresql-client && \
    pip3 install ansible

# Clone and install AWX from source
RUN git clone -b 21.14.0 https://github.com/ansible/awx.git /awx
WORKDIR /awx/installer

COPY install_awx.sh /install_awx.sh
RUN chmod +x /install_awx.sh

CMD ["/install_awx.sh"]