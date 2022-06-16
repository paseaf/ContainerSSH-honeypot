# modified from https://github.com/ContainerSSH/guest-image/blob/main/Dockerfile
FROM containerssh/agent:latest AS agent

FROM ubuntu:22.04

RUN echo "\e[1;32mUpdating packages and installing SFTP server package...\e[0m" && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' update && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' -fuy --allow-downgrades --allow-remove-essential --allow-change-held-packages upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' -fuy --allow-downgrades --allow-remove-essential --allow-change-held-packages dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' -fuy --allow-downgrades --allow-remove-essential --allow-change-held-packages install ssh && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' -y autoremove && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' -y clean

RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 ubuntu
USER ubuntu
WORKDIR /home/ubuntu

COPY --from=agent /usr/bin/containerssh-agent /usr/bin/containerssh-agent

CMD ["/bin/bash"]
SHELL ["/bin/bash"]
ONBUILD RUN echo "The ContainerSSH guest image is not intended as a base image and may change at any time. Please build your own image." >&2 && exit 1
