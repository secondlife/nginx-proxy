# nginx-proxy

A reverse proxy container with safe defaults for production environments.

## Use

Pair nginx-proxy with your favorite upstream server (wsgi, uwsgi, asgi, et al.)

| Environment Variable | Description | Required | Default | Example |
|----------------------|-------------|----------|---------|---------|
| `PROXY_REVERSE_URL` | Upstream server URL | Yes | | http://myapp:8080 |
| `LISTEN_PORT` | Server port | Yes | 8080 | |
| `SILENT` | Silence entrypoint output | No | | |

## Development

A test suite is baked into nginx-proxy's Dockerfile. You can run it by building
the test layer: `docker build --target test .`

[nginx container]: https://hub.docker.com/_/nginx
[mo]: https://github.com/tests-always-included/mo

### Differences from standard nginx container

Notable differences from the official [nginx container][]

- [mo][] is used to render nginx configuration templates so that image startup
  is aborted if a template variable is missing. This is an improvement over the
  official image, which uses `envsubst`. 
- alpine's official nginx package is used in order to ensure compatibility with
  distro-provided nginx modules. This is another enhancement, as the official
  image cannot be used with alpine's nginx modules.
