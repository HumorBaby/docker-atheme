ARG ALPINE_TAG=3.8
FROM alpine:${ALPINE_TAG}

## Build ARGs
# Autobuild
ARG DEBUG_BUILD
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL=https://github.com/HumorBaby/docker-atheme
# Atheme details
ARG ATHEME_REPO=https://github.com/atheme/atheme.git
ARG ATHEME_TAG=v7.2.10-r2
# libmowgli-2 as is has issues compiling on alpine with musl.
# For now, a different branch will be patched in that is based on
# the exact commit referred to by libmowgli-2 in atheme/atheme (12c57bf)
# with a one line changed in a single commit.
ARG LIBMOWGLI_REPO=https://github.com/HumorBaby/libmowgli-2.git
ARG LIBMOWGLI_BRANCH=fix-musl-compile-track-atheme-v7.2.10-r2
##
# UID to assign atheme user
ARG _UID=100000
# Additional arguments to ./configure
ARG CONFIG_ARGS="--enable-contrib"

## Label image
LABEL maintainer="HumorBaby <https://github.com/HumorBaby>" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.name="atheme" \
      org.label-schema.description=" \
        Alpine based atheme image. \
        For stand-alone or compose/stack service use." \
      org.label-schema.url="${VCS_URL}" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="${VCS_URL}" \
      org.label-schema.version="${ATHEME_TAG}" \
      org.label-schema.schema-version="1.0"

RUN \
  # Exit on any error (non-zero status) (-e)
  set -e \
  # Print commands if DEBUG_BUILD is set (-x)
  && { [ ! -z "${DEBUG_BUILD}" ] && set -x || true; } \
\
  # Install build deps
  && apk add --no-cache --virtual .build-deps \
    build-base \
    git \
  # Install atheme dependencies
  && apk add --no-cache \
    openssl-dev \
    $(echo ${CONFIG_ARGS} | grep -q 'enable-contrib' && echo 'libexecinfo-dev') \
\
  # Make unpriviledged atheme user
  && adduser -u ${_UID} -h /atheme/ -D -S atheme \
\
  # Clone source
  && git clone --branch "${ATHEME_TAG}" --depth 1 "${ATHEME_REPO}"  /src \
  && cd /src \
  && git submodule update --init \
  # Replace libmowgli
  && rm -rf ./libmowgli-2 \
  && git clone --branch "${LIBMOWGLI_BRANCH}" --depth 1 "${LIBMOWGLI_REPO}" \
    ./libmowgli-2 \
\
  # Build and install
  && ./configure --prefix=/atheme/. ${CONFIG_ARGS} \
  && make \
  && make install \
\
  # Clean up
  && apk del .build-deps \
  && rm -rf /src \
\
  # Transfer ownership to atheme user
  && chown -R atheme /atheme 

# Make docker volumes for important directories
VOLUME [ "/atheme/etc", "/atheme/var" ]

WORKDIR /atheme
USER atheme

COPY ./docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/atheme/bin/atheme-services", "-n" ]