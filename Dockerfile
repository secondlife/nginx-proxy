############
# Base 
############
ARG ARCH=
FROM artifactory.secondlife.io/dockerhub/${ARCH}alpine:3 AS base
RUN apk add --no-cache \
    bash \
    nginx \
    nginx-mod-http-headers-more
COPY src /
ENV LISTEN_PORT=80
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
