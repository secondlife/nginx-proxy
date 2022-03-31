############
# Base 
############
ARG ARCH=
FROM artifactory.secondlife.io/dockerhub/${ARCH}alpine:3 AS base
ARG GOMPLATE_ARCH=amd64
ARG GOMPLATE_SHA256=603539aac4e09f98a8ca5b6e5da0c21213221206dc7175a5644255c7a22b936d
ARG GOMPLATE_VERSION=3.10.0
ADD https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-${GOMPLATE_ARCH}-slim /usr/local/bin/gomplate
RUN echo "${GOMPLATE_SHA256}  /usr/local/bin/gomplate" | sha256sum -c \
    && chmod +x /usr/local/bin/gomplate \
    && apk add --no-cache \
        bash \
        nginx \
        nginx-mod-http-headers-more
COPY src /
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
RUN apk add --no-cache curl go
COPY test /test
WORKDIR /test
RUN /test/test.sh

############
# Final 
############
LABEL "com.datadoghq.ad.check_names"='["nginx"]'
LABEL "com.datadoghq.ad.init_configs"='[{}]'
LABEL "com.datadoghq.ad.instances"='[{"nginx_status_url": "http://%%host%%:81/nginx_status/"}]'
FROM base
