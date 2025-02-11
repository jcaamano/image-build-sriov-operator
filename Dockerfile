ARG TAG="v1.0.0"
ARG UBI_IMAGE=registry.access.redhat.com/ubi7/ubi-minimal:latest
ARG GO_IMAGE=rancher/hardened-build-base:v1.15.8b5

# Build the project
FROM ${GO_IMAGE} as builder
RUN set -x \
 && apk --no-cache add \
    git \
    make \
    patch
ARG TAG
ENV CGO_ENABLED=0
COPY 0001-CGO_ENABLED.patch . 
RUN git clone https://github.com/k8snetworkplumbingwg/sriov-network-operator \
    && cd sriov-network-operator \
    && git fetch --all --tags --prune \
    && git checkout ${TAG} -b ${TAG} \
    && patch -p1 < ../0001-CGO_ENABLED.patch \
    && make clean && make _build-manager

# Create the sriov-cni image
FROM ${UBI_IMAGE}
WORKDIR /
COPY --from=builder /go/sriov-network-operator/build/_output/linux/amd64/manager /usr/bin/sriov-network-operator
COPY --from=builder /go/sriov-network-operator/bindata /bindata
ENTRYPOINT ["/usr/bin/sriov-network-operator"]
