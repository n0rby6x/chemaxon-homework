# syntax=docker/dockerfile:1
#
# Builds the "rest_1.0" Go REST service (downloaded/unzipped by
# scripts/build-and-deploy.sh into ./app before this Dockerfile is built).
#
# NOTE: this assumes a standard Go module layout with go.mod + a main
# package at the repo root of the unzipped app. If the actual archive uses a
# different layout (e.g. source under cmd/server/), adjust the `COPY` /
# `go build` line below accordingly - see the README for details.

FROM golang:1.22-alpine AS build

WORKDIR /src
COPY app/ .

RUN go mod download 2>/dev/null || true
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/server .

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/server /server

EXPOSE 8080
ENTRYPOINT ["/server"]
