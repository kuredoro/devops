# Docker best practices

## `.dockerignore`

`.dockerignore` tells docker which files to exclude from the build context. When one calls `docker build` the build context (the files available to docker) is considered to be the current working directory. Subsequently, these files are transferred to the daemon which takes time. To reduce the copying, declare which files to exclude from build context inside `.dockerignore`.

## Keep number of layers small

Each instruction in Dockerfile creates a new read-only file system layer(\*) that consists of delta between new and old FS state. Thus to increase the build times, it's best to keep the number of layers small.

(\*) Only `RUN`, `COPY`, and `ADD` commands generate layers, other commands generate intermediate images.

## Leverage build cache

The build cache allows to remember the results of commands and reuse them if no changes to the build context happened. So, for example, if you have `COPY foo.txt /`, and you run `docker build` for the first time, it will take time to actually copy that file to a new layer, but the subsequent calls to `docker build` will not copy the file and rebuild the layer, if the file was not changed. Cache invalidation is what happens when the file actually changes: the layer is rebuilt. But so are all of the consequent layers! This means that to minimize the number of layer rebuilds, you need to list commands from the most unlikely to change to the most likely. Example:

```
FROM golang:1.16-alpine

# Install tools required for project
# Run `docker build --no-cache .` to update dependencies
RUN apk add --no-cache git

# List project dependencies with Gopkg.toml and Gopkg.lock
# These layers are only re-built when Gopkg files are updated
COPY go.mod go.sum /go/src/project/
WORKDIR /go/src/project/
# Install library dependencies
RUN go mod download

# Copy the entire project and build it
# This layer is rebuilt when a file changes in the project directory
COPY . /go/src/project/
RUN go build -o /bin/project

ENTRYPOINT ["/bin/project"]
CMD ["--help"]
```

This way you make sure your builds keep being fast.

*Note.* With `ADD`, and `COPY` it's clear that cache is invalidated when the files change. But `RUN` is not so. The rule is that if `RUN` was already cached, the cache is taken, meaning that to, say, update dependencies, the cache should be disabled.

## Use multi-stage builds

When docker runs commands from Dockerfile, each file and each FS layer contridutes to the size of the image. And the greatest problem of docker is keeping the size small.

Suppose you have two dockerfiles: one for development and one for release. Your development image will contain everything to build your project, but the release one should contain only the executable. How can this be achieved? You can just copy-paste development Dockerfile, call it Dockerfile.release and tell the `ENTRYPOINT`, right? The problem is the size of the image. Release image doesn't need all the files left out from building the project, it needs just one. But the hard drive is occupied by the two same-sized images.

Multi-stage builds solve this: at any line in Dockerfile you can write `FROM` command to start building a new image. Everything that was created prior is discarded from it. And when a file from previous image is need, you use the `COPY` command specifying the image.

```
FROM golang:1.16 as build    # We give name to this image "build".
COPY app.go /
RUN go build -o app .

FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=build /app .     # Specify the image to copy the file from.
CMD ["./app"]  
```

## Use linters

One can use linters to check for conformance of these rules and to perform additional checks, like making sure the bash scripts are correct. One such linter is hadolint.
