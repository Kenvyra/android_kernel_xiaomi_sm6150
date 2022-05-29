#!/usr/bin/bash
podman build -t kernel:latest .
podman run --rm -it --name kernel --security-opt label=disable --userns=keep-id --mount type=tmpfs,tmpfs-size=5G,destination=/build -v $(pwd):/src kernel:latest $1
