===== SonicWall ConnectTunnel VPN on Docker =====

You can download the latest SonicWall ConnectTunnel VPN client for linux64 from
https://www.sonicwall.com/products/remote-access/vpn-clients/

or just run
```
wget https://software.sonicwall.com/CT-NX-VPNClients/CT-12.4.2/ConnectTunnel_Linux64-12.42.00631.tar
```
to download the same version distributed with the repo.

Put the file within the content/ folder and adjust the Docker file to point to the client version you've just downloaded.

Create the configuration file:
```
cp config.env.sample config.env
edit config.env
```

Build the container image:
```
./build.sh
```

Check options:
```
./start.sh -h
```

Run the container and forward some routes between host and container:
```
./start.sh -r 10.10.10.0/24 -r 192.168.12.0/24
```

or make the container using host networking:
```
./start.sh --use-host-net
```
