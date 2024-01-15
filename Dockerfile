############
# Gomplate 
############
FROM alpine:3 AS gomplate 
ARG TARGETPLATFORM=linux/amd64
ARG GOMPLATE_VERSION=3.10.0
ARG GOMPLATE_AMD64_SHA256=603539aac4e09f98a8ca5b6e5da0c21213221206dc7175a5644255c7a22b936d
ARG GOMPLATE_ARM64_SHA256=3352ef521977ee39cdd406a9a7943d0b5f29772e5542995416bf093b90bbae2c
RUN apk add --no-cache curl bash
SHELL ["/bin/bash", "-c"]
RUN ARCH=${TARGETPLATFORM/linux\//} \
    && curl -Lf https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-${ARCH}-slim -o /tmp/gomplate \ 
    && sha_envvar="GOMPLATE_${ARCH^^}_SHA256" \
    && GOMPLATE_SHA256="${!sha_envvar}" \
    && echo "${GOMPLATE_SHA256}  /tmp/gomplate" | sha256sum -c \
    && chmod +x /tmp/gomplate

############
# Base 
############
FROM alpine:3 AS base
COPY --from=gomplate /tmp/gomplate /usr/local/bin/
RUN apk add --no-cache \
        bash \
        nginx \
        nginx-mod-http-headers-more
COPY src /
ENV KEEPALIVE_TIMEOUT=65
ENV PROXY_UWSGI=0
ENV LISTEN_PORT=80
ENV STATIC_LOCATIONS=
EXPOSE 80
STOPSIGNAL SIGQUIT
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

############
# Run tests
############
FROM base AS test
RUN apk add --no-cache curl go uwsgi-python3

COPY test /test
WORKDIR /test
RUN /test/test.sh

COPY test_uwsgi /test_uwsgi
WORKDIR /test_uwsgi
RUN /test_uwsgi/test.sh

############
# Final 
############
FROM base
LABEL "com.datadoghq.ad.check_names"='["nginx"]'
LABEL "com.datadoghq.ad.init_configs"='[{}]'
LABEL "com.datadoghq.ad.instances"='[{"nginx_status_url": "http://%%host%%:81/nginx_status/"}]'
