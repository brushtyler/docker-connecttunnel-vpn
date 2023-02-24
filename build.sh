#!/bin/bash

IMAGENAME=sonicwall-connect-tunnel-vpn

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPTDIR"
docker build -t "$IMAGENAME" .
