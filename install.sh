#!/bin/bash
set -e
export CGO_ENABLED=0 GOPATH=~/go
grep opstreelabs.in -rl | grep -E '(go|yaml|PROJECT)$' | while read -r f; do
  sed "s~opstreelabs.instance~k8s.instance~g;s~opstreelabs.in~k8s.vip~g;s~opstreelabs~k8s~g" <"$f" >abc
  mv abc "$f"
done
go mod tidy
git diff | grep "^[+-]" || true
for GOARCH in amd64 arm64; do
  export GOARCH=$GOARCH
  mkdir -p .git/$GOARCH
  go build -trimpath -ldflags '-s -w -extldflags "-static"' -o $GOPATH/bin/operator cmd/main.go
  cp -av $GOPATH/bin/operator .git/$GOARCH
done
