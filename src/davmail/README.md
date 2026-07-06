# DavMail in container

[Davmail Gateway](http://davmail.sourceforge.net/) in a container

Auto choose latest Davmail version

## Quickstart

You need a `davmail.properties` configuration. If you don't know how click [here](http://davmail.sourceforge.net/serversetup.html).

Run the container:

``` bash
DAVMAIL_CONF=<absolute/path/to/davmail.properties>
DAVMAIL_LOG=<absolute/path/to/davmail.log>
[docker|podman] run --name davmail -d -v ${DAVMAIL_CONF}:/etc/davmail -v ${DAVMAIL_LOG}:/var/log/davmail mukhumaev/davmail
```

Build multiarch:
```bash
make build IMAGE=mukhumaev/davmail TAG=latest ARCH_PLATFORMS=linux/arm/v7,linux/arm64,linux/amd64
```

## Exposed ports

The following ports are exposed by the container:

* caldav: 1080
* imap: 1143
* ldap: 1389
* pop: 1110
* smtp: 1025

