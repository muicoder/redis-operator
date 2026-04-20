#!/bin/sh

set -e

VERSION="${1:-$(curl -fsSLk "https://api.github.com/repos/alibaba/RedisShake/releases/latest" | grep .tag_name | awk -F\" '{print $(NF-1)}')}"

echo https://github.com/moparisthebest/static-curl
[ -s curl ] || curl -fsSLko curl "https://github.com/moparisthebest/static-curl/releases/download/$(curl -fsSLk "https://api.github.com/repos/moparisthebest/static-curl/releases/latest" | grep .tag_name | awk -F\" '{print $(NF-1)}')/curl-amd64"
echo https://github.com/ken-matsui/jyt
[ -s jyt ] || docker run --rm --entrypoint sh -v "$PWD:/pwd" -w /pwd muicoder/redis-shake:v3 -c 'cp -av /usr/bin/jyt .'

chmod a+x curl jyt

cat <<EOF >Dockerfile
FROM ubuntu:22.04
COPY --chown=0:0 curl jyt /usr/bin/
RUN curl -fsSLk https://github.com/alibaba/RedisShake/releases/download/$VERSION/redis-shake-linux-amd64.tar.gz | tar -xz
EOF

docker build --network host -t "muicoder/redis-shake:${VERSION%%.*}" --push .
