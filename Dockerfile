FROM registry.fedoraproject.org/fedora-minimal:rawhide

# Install all dependencies
RUN microdnf install -y git-core diffutils findutils glibc-headers-x86 glibc-devel openssl-devel which bc bash perl python3 tar xz

COPY entrypoint.sh /

ENTRYPOINT ["/usr/bin/bash", "entrypoint.sh"]
