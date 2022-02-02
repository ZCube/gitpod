# Copyright (c) 2020 Gitpod GmbH. All rights reserved.
# Licensed under the GNU Affero General Public License (AGPL).
# See License-AGPL.txt in the project root for license information.

# BUILDER_BASE is a placeholder, will be replaced before build time
# Check BUILD.yaml
FROM ubuntu:18.04 as code_installer

# we use latest major version of Node.js distributed VS Code. (see about dialog in your local VS Code)
# ideallay we should use exact version, but it has criticla bugs in regards to grpc over http2 streams
ARG NODE_VERSION=14.18.2

RUN apt-get update \
    # see https://github.com/microsoft/vscode/blob/42e271dd2e7c8f320f991034b62d4c703afb3e28/.github/workflows/ci.yml#L94
    && apt-get -y install --no-install-recommends libxkbfile-dev pkg-config libsecret-1-dev libxss1 dbus xvfb libgtk-3-0 libgbm1 \
    && apt-get -y install --no-install-recommends git curl build-essential libssl-dev ca-certificates python \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV NVM_DIR /root/.nvm
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh  \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && npm install -g yarn node-gyp
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

ARG CODE_COMMIT

ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1
ENV ELECTRON_SKIP_BINARY_DOWNLOAD 1

RUN mkdir gp-code \
    && cd gp-code \
    && git init \
    && git remote add origin https://github.com/gitpod-io/vscode \
    && git fetch origin $CODE_COMMIT --depth=1 \
    && git reset --hard FETCH_HEAD
WORKDIR /gp-code
RUN yarn --frozen-lockfile --network-timeout 180000
RUN yarn --cwd ./extensions compile
RUN yarn gulp vscode-web-min
RUN arch="$(uname -m)"; \
	case "$arch" in \
		'x86_64') \
			yarn gulp vscode-reh-linux-x64-min \
                        && mv /vscode-reh-linux-x64 /vscode-reh-linux \
			;; \
		'aarch64') \
			yarn gulp vscode-reh-linux-arm64-min \
                        && mv /vscode-reh-linux-arm64 /vscode-reh-linux \
			;; \
		*) echo >&2 "error: unsupported architecture '$arch'"; exit 1 ;; \
	esac;

# config for first layer needed by blobserve
# we also remove `static/` from resource urls as that's needed by blobserve,
# this custom urls will be then replaced by blobserve.
# Check pkg/blobserve/blobserve.go, `inlineVars` method
RUN cp /vscode-web/out/vs/gitpod/browser/workbench/workbench.html /vscode-web/index.html \
    && sed -i -e 's#static/##g' /vscode-web/index.html

# cli config: alises to gitpod-code
# can't use relative symlink as they break when copied to the image below
COPY bin /ide/bin
RUN chmod -R ugo+x /ide/bin

# grant write permissions for built-in extensions
RUN chmod -R ugo+w /vscode-reh-linux/extensions

FROM ubuntu:18.04
# copy static web resources in first layer to serve from blobserve
COPY --from=code_installer --chown=33333:33333 /vscode-web/ /ide/
COPY --from=code_installer --chown=33333:33333 /vscode-reh-linux/ /ide/
COPY --chown=33333:33333 startup.sh supervisor-ide-config.json /ide/

COPY --from=code_installer --chown=33333:33333 /ide/bin /ide/bin/remote-cli

ENV GITPOD_ENV_APPEND_PATH /ide/bin/remote-cli:

# editor config
ENV GITPOD_ENV_SET_EDITOR /ide/bin/remote-cli/gitpod-code
ENV GITPOD_ENV_SET_VISUAL "$GITPOD_ENV_SET_EDITOR"
ENV GITPOD_ENV_SET_GP_OPEN_EDITOR "$GITPOD_ENV_SET_EDITOR"
ENV GITPOD_ENV_SET_GIT_EDITOR "$GITPOD_ENV_SET_EDITOR --wait"
ENV GITPOD_ENV_SET_GP_PREVIEW_BROWSER "/ide/bin/remote-cli/gitpod-code --preview"
ENV GITPOD_ENV_SET_GP_EXTERNAL_BROWSER "/ide/bin/remote-cli/gitpod-code --openExternal"
