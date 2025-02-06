# Lingua Franca RTI Dockerfile

Build a docker image containing the Lingua Franca RTI.

## Platforms supported

- linux/amd64
- linux/aarch64 (linux/arm/v8)
- linux/arm/v7
- linux/riscv64

## How to use

```shell
docker build .
```

### Build arguments

- `BASEIMAGE`: the base image to use for building and for the application stage. Defaults to a tagged release of Ubuntu 24.04.
- `RTI_GIT_REF`: git hash, branch or tag to checkout of [lf-lang/reactor-c](https://github.com/lf-lang/reactor-c).
- `RTI_USE_SSL`: build RTI with the compile option `-DAUTH=ON` and install openssl.
