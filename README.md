# Container Images

This repository contains a Make-based script to build and publish container images. The Containerfile is located at `src/IMAGE/Containerfile`.

Supported Make targets:

- list
  Lists available Containerfiles that can be built.

- build
  Build a local image for the current architecture. Uses `src/IMAGE/Containerfile` and tags the image locally.

- release
  Push a image to the registry for the current architecture. Assumes you are logged in to the registry and have the required variables set (e.g., image name/repository). Architectures are listed in the `ARCH_PLATFORMS` variable in the Makefile (for example: `ARCH_PLATFORMS=linux/amd64,linux/arm64`). The Makefile builds images for the specified platforms and creates/pushes a multi-arch manifest.

- help
  Show this help message.

Containerfile location

```
src/IMAGE/Containerfile
```

You can add extra Containerfiles under `src/` — the `list` target should discover them.

Environment variables and parameters

- ARCH_PLATFORMS
  List of platforms for `release`. Example:
  ```
  ARCH_PLATFORMS=linux/amd64,linux/arm64
  ```

- Image name / tag variables
  The Makefile may expect variables such as `IMAGE` and `TAG`. Examples:
  ```
  make build IMAGE=myrepo/myimage TAG=latest
  make release IMAGE=myrepo/myimage TAG=1.0.0 ARCH_PLATFORMS="linux/amd64,linux/arm64"
  ```

- Registry login
  For `release` you must be authenticated to the target registry:
  ```
  docker login <registry>
  ```

- CONTAINER_MANAGER — container manager to use (e.g., `buildah`, `podman` or `docker`). Default: `buildah`. Example:
  ```
  make build CONTAINER_MANAGER=podman IMAGE=myrepo/myimage TAG=latest
  ```

Examples

- Show available Containerfiles:
  ```
  make list
  ```

- Build a local image for the current architecture:
  ```
  make build IMAGE=myrepo/myimage TAG=latest
  ```

- Publish a single-arch image for your device's current architecture:
  ```
  make release IMAGE=myrepo/myimage TAG=1.0.0
  ```

- Build and push a multi-arch image:
  ```
  make release IMAGE=myrepo/myimage TAG=1.0.0 ARCH_PLATFORMS="linux/amd64,linux/arm64"
  ```
