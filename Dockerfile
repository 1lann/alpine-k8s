FROM busybox:stable-musl AS sh-static

FROM alpine:3.17

# Ignore to update versions here
ARG HELM_VERSION=3.10.3
ARG KUBECTL_VERSION=1.25.5
ARG KUSTOMIZE_VERSION=v4.5.7
ARG KUBESEAL_VERSION=0.19.3
ARG TARGETARCH

# Install helm (latest release)
# ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz"
RUN apk add --update --no-cache curl ca-certificates bash git && \
    curl -sL ${BASE_URL}/${TAR_FILE} | tar -xvz && \
    mv linux-${TARGETARCH}/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-${TARGETARCH}

# add helm-diff
RUN helm plugin install https://github.com/databus23/helm-diff && rm -rf /tmp/helm-*

# # add helm-unittest
# RUN helm plugin install https://github.com/quintush/helm-unittest && rm -rf /tmp/helm-*

# add helm-push
RUN helm plugin install https://github.com/chartmuseum/helm-push && rm -rf /tmp/helm-*

# Install kubectl (same version of aws esk)
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl && \
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# Install kustomize (latest release)
RUN curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_${TARGETARCH}.tar.gz && \
    tar xvzf kustomize_${KUSTOMIZE_VERSION}_linux_${TARGETARCH}.tar.gz && \
    mv kustomize /usr/bin/kustomize && \
    chmod +x /usr/bin/kustomize

# Install eksctl (latest version)
RUN curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_${TARGETARCH}.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/bin && \
    chmod +x /usr/bin/eksctl

# Install awscli
RUN apk add --update --no-cache python3 && \
    python3 -m ensurepip && \
    pip3 install --upgrade pip && \
    pip3 install awscli && \
    pip3 cache purge

# Install jq
RUN apk add --update --no-cache jq yq

# # https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
# # Install aws-iam-authenticator (latest version)
# RUN authenticator=$(curl -fs https://api.github.com/repos/kubernetes-sigs/aws-iam-authenticator/releases/latest | jq --raw-output '.name' | sed 's/^v//') && \
#     curl -fL https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${authenticator}/aws-iam-authenticator_${authenticator}_linux_${TARGETARCH} -o /usr/bin/aws-iam-authenticator && \
#     chmod +x /usr/bin/aws-iam-authenticator

# Install for envsubst
RUN apk add --update --no-cache gettext

# Install kubeseal
RUN curl -L https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${TARGETARCH}.tar.gz -o - | tar xz -C /usr/bin/ && \
    chmod +x /usr/bin/kubeseal

RUN rm /bin/sh

COPY --from=sh-static /bin/sh /bin/sh

WORKDIR /apps
