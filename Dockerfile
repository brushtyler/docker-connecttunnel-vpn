FROM ubuntu:20.04

RUN \
    apt update && \
    apt install -y bzip2 default-jdk \
        expect kmod net-tools iproute2 iptables

ADD content/ConnectTunnel_Linux64-12.42.00631.tar /src

WORKDIR /src
RUN \
    mkdir /dev/net && mknod /dev/net/tun c 10 200 && \
    /src/install.sh

ADD content/entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
