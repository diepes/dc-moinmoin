MoinMoin wiki in a docker container
===================================

Fork from https://github.com/lukasnellen/dc-moinmoin (2021-last update 3years ago)

Goal to run local MoinMoin wiki, that needs python2.7 on system with only python3+

Build
-----
The docker build (using podman) creates base python2.7 and then pip installs 
moinmoin from tar.gz file main-1.9.11.tar.gz.

The gunicorn (Green Unicorn) wsgi python web server serves the moinmoin site.

To run, mount three volumes into the container.
1. data  - the site data
2. underlay - static pages - install with http:<container>:8000/language_setup/LanguageSetup?action=language_setup
3. moin config

I setup the container behind nginx
'''
        location / {
            # checks for static file, if not found proxy to app
            try_files $uri @proxy_to_app;
        }
      location @proxy_to_app {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $http_host;
            # we don't want nginx trying to do something clever with
            # redirects, we set the Host: header above already.
            proxy_redirect off;
            # Docker moinmoin
            proxy_pass http://127.0.0.1:8080;
       }
'''


### Running without starting the regular container

```sh
podman run --rm <id> sh
```

This allows you to work with the container even when you cannot use
`docker-compose up` to start the container first. This can be handy
for preparing or migrating the wiki before serving the contents. Note
that this will create an extra container.

### Running inside the wiki container

```sh
podman exec <id> sh
```

