#!/bin/bash
set -e
export CGO_ENABLED=0 GOPATH=~/go
go mod tidy
git diff | grep "^[+-]" || true
for GOARCH in amd64 arm64; do
  export GOARCH=$GOARCH
  mkdir -p .git/$GOARCH
  go build -trimpath -ldflags '-s -w -extldflags "-static"' -o $GOPATH/bin/operator cmd/main.go
  cp -av $GOPATH/bin/operator .git/$GOARCH
done
