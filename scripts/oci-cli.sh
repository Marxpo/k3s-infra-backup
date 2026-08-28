#!/bin/bash
docker run --rm -i -v oci-config:/oracle/.oci ghcr.io/oracle/oci-cli:latest "$@"
