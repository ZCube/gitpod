# Copyright (c) 2020 Gitpod GmbH. All rights reserved.
# Licensed under the GNU Affero General Public License (AGPL).
# See License-AGPL.txt in the project root for license information.

FROM alpine:3.15 as dl
WORKDIR /dl
RUN arch="$(uname -m)"; \
	case "$arch" in \
		'x86_64') \
			export ARCH='x86_64' \
			;; \
		'aarch64') \
			export ARCH='arm64' \
			;; \
		*) echo >&2 "error: unsupported architecture '$arch'"; exit 1 ;; \
	esac; \
  apk add --no-cache curl \
  && curl -o runc -L https://github.com/opencontainers/runc/releases/download/v1.1.0/runc.${ARCH} \
  && chmod +x runc

FROM alpine:3.15

RUN apk upgrade \
  && rm -rf /var/cache/apk/*

## Installing coreutils is super important here as otherwise the loopback device creation fails!
RUN apk add --no-cache git bash openssh-client lz4 e2fsprogs coreutils tar strace xfsprogs-extra

RUN apk add --no-cache kubectl --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

COPY --from=dl /dl/runc /usr/bin/runc

# Add gitpod user for operations (e.g. checkout because of the post-checkout hook!)
RUN addgroup -g 33333 gitpod \
    && adduser -D -h /home/gitpod -s /bin/sh -u 33333 -G gitpod gitpod \
    && echo "gitpod:gitpod" | chpasswd

COPY components-ws-daemon--app/ws-daemon /app/ws-daemond
COPY components-ws-daemon--content-initializer/ws-daemon /app/content-initializer
COPY components-ws-daemon-nsinsider--app/nsinsider /app/nsinsider

USER root

ARG __GIT_COMMIT
ARG VERSION

ENV GITPOD_BUILD_GIT_COMMIT=${__GIT_COMMIT}
ENV GITPOD_BUILD_VERSION=${VERSION}
ENTRYPOINT [ "/app/ws-daemond" ]
CMD [ "-v", "help" ]
