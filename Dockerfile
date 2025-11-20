############
# Base
############
FROM alpine:3 AS base
RUN apk add --no-cache \
        bash \
        gomplate \
        nginx \
        nginx-mod-http-headers-more
COPY src /
ENV KEEPALIVE_TIMEOUT=65
ENV PROXY_UWSGI=0
ENV NGINX_RESOLVER=
ENV UPSTREAM_RESOLVE=0
ENV LISTEN_PORT=80
ENV STATUS_LISTEN_PORT=8091
ENV HEALTHCHECK_PATH="/lb-status/"
ENV STATIC_LOCATIONS=
ENV NO_ACCESS_LOGS=0
ENV LOG_ONLY_5XX=0
ENV WORKER_CONNECTIONS=1024
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
LABEL "com.datadoghq.ad.instances"='[{"nginx_status_url": "http://%%host%%:%%env_STATUS_LISTEN_PORT%%/nginx_status/"}]'
