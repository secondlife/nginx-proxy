# nginx-proxy

A reverse proxy container with safe defaults for production environments.

## Use

Pair nginx-proxy with your favorite upstream server (wsgi, uwsgi, asgi, et al.)

| Environment Variable | Description | Required | Default | Example |
|----------------------|-------------|----------|---------|---------|
| `PROXY_REVERSE_URL` | Upstream server URL | Yes | | http://myapp:8080 |
| `LISTEN_PORT` | Server port | Yes | 8080 | |
| `SILENT` | Silence entrypoint output | No | | |
| `STATIC_LOCATIONS` | Static asset mappings | No | | |

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
