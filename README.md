# Container Images

This repository contains a Make-based script to build and publish container images. The Dockerfile is located at `src/IMAGE/Dockerfile`.

Supported Make targets:

- list
  Lists available Dockerfiles that can be built.

- build
  Build a local image for the current architecture. Uses `src/IMAGE/Dockerfile` and tags the image locally.

- release
  Push a single-architecture image to the registry for the current architecture. Assumes you are logged in to the registry and have the required variables set (e.g., image name/repository).

- release-multi
  Build and push a multi-architecture image. Architectures are listed in the `ARCH_PLATFORMS` variable in the Makefile (for example: `ARCH_PLATFORMS=linux/amd64,linux/arm64`). The Makefile builds images for the specified platforms and creates/pushes a multi-arch manifest.

- help
  Show this help message.

Dockerfile location

```
src/IMAGE/Dockerfile
```

You can add extra Dockerfiles under `src/` — the `list` target should discover them.

Environment variables and parameters

- ARCH_PLATFORMS
  List of platforms for `release-multi`. Example:
  ```
  ARCH_PLATFORMS=linux/amd64,linux/arm64
  ```

- Image name / tag variables
  The Makefile may expect variables such as `IMAGE` and `TAG`. Examples:
  ```
  make build IMAGE=myrepo/myimage TAG=latest
  make release IMAGE=myrepo/myimage TAG=1.0.0
  make release-multi IMAGE=myrepo/myimage TAG=1.0.0 ARCH_PLATFORMS="linux/amd64,linux/arm64"
  ```

- Registry login
  For `release` and `release-multi` you must be authenticated to the target registry:
  ```
  docker login <registry>
  ```

- CONTAINER_MANAGER — container manager to use (e.g., `podman` or `docker`). Default: `docker`. Example:
  ```
  make build CONTAINER_MANAGER=podman IMAGE=myrepo/myimage TAG=latest
  ```

Examples

- Show available Dockerfiles:
  ```
  make list
  ```

- Build a local image for the current architecture:
  ```
  make build IMAGE=myrepo/myimage TAG=latest
  ```

- Publish a single-arch image:
  ```
  make release IMAGE=myrepo/myimage TAG=1.0.0
  ```

- Build and push a multi-arch image:
  ```
  make release-multi IMAGE=myrepo/myimage TAG=1.0.0 ARCH_PLATFORMS="linux/amd64,linux/arm64"
  ```
