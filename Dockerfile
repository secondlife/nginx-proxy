############
# Base 
############
FROM artifactory.secondlife.io/dockerhub/alpine:3 AS base
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
FROM base
