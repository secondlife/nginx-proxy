# nginx-proxy

A reverse proxy container with safe defaults for production environments.

## Use

Pair nginx-proxy with your favorite upstream server (wsgi, uwsgi, asgi, et al.)

| Environment Variable | Description | Required | Default | Example |
|----------------------|-------------|----------|---------|---------|
| `LISTEN_PORT` | Server port | Yes | 80 | |
| `UPSTREAM_SERVER` | Upstream server | Yes | | myapp:8080 fail_timeout=0, unix://mnt/server.sock |
| `PROXY_REVERSE_URL` | Upstream server URL (Deprecated, please use UPSTREAM_SERVER) | No | | http://myapp:8080 |
| `SERVER_NAME` | Allowed server names (hostnames) | Yes | | |
| `SILENT` | Silence entrypoint output | No | | |
| `STATIC_LOCATIONS` | Static asset mappings | No | | |
| `PROXY_UWSGI` | Whether to use native uwsgi support | No | 0 | 1 |
| `KEEPALIVE_TIMEOUT` | What value to set HTTP keepalive (This should be higher than your ELB's timeout) | Yes | 65 | |

### Hosting Static Assets

Static files can be hosted from your proxied application by sharing a volume
mount between nginx-proxy and your app container then defining a list of
hosted directories using `STATIC_LOCATIONS`.

In ECS, you can mount directies with with the `volumesFrom` directive. With
docker-compose like so:

```yaml
services:
  app:
    # ...
    volumes:
      static:/var/www/static
  proxy:
    # ...
    environment:
      STATIC_LOCATIONS:/static/:/var/www/static/
    volumes:
      static:/var/www/static
volumes:
  static:
```

The syntax of `STATIC_LOCATIONS` is `HOSTED_PATH1:LOCAL_PATH1,HOSTED_PATH2:LOCAL_PATH2`

## uWSGI

If you wish to use this service with uWSGI then define `PROXY_UWSGI=1` and set
`UPSTREAM_SERVER` to be the uwsgi `--socket` address of your app. (Do not
use `http://`, ex. if your uwsgi server is hosting itself at `--socket :8000`
then set `PROXY_REVERSE_URL=localhost:8000`.)

## Development

A test suite is baked into nginx-proxy's Dockerfile. You can run it by building
the test layer: `docker build --target test .`

### Differences from standard nginx container

Notable differences from the official [nginx container][]

- [gomplate][] is used to render nginx configuration templates so that image startup
  is aborted if a template variable is missing. This is an improvement over the
  official image, which uses `envsubst`. 
- alpine's official nginx package is used in order to ensure compatibility with
  distro-provided nginx modules. This is another enhancement, as the official
  image cannot be used with alpine's nginx modules.

[nginx container]: https://hub.docker.com/_/nginx
[gomplate]: https://docs.gomplate.ca/
