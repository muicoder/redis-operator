#!/bin/sh

set -e

cd "$(dirname "$0")" >/dev/null || exit
# https://github.com/redis/redis/blob/unstable/utils/gen-test-certs.sh

readonly NS="${1:-default}"       # Namespace for kubernetes
readonly RN="${2:-redis}"         # ReleaseName for helm
readonly mode="${3:-replication}" # standalone cluster replication sentinel

readonly manifest="${4:-$0.yaml}" # write to yaml

SIZE="$(grep ^size: values.yaml | awk '{print $2}')"

mkdir -p tls

cat <<EOF >"openssl.conf"
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
$(
  if [ "$mode" = standalone ]; then
    echo "DNS.0 = $RN-0"
  else
    for i in $(seq 0 "$((SIZE - 1))"); do
      if [ "$mode" = cluster ]; then
        echo "DNS.$i = $RN-leader-$i"
        echo "DNS.$((SIZE + i)) = $RN-follower-$i"
      elif [ "$mode" = replication ]; then
        echo "DNS.$i = $RN-$i"
      elif [ "$mode" = sentinel ]; then
        echo "DNS.$i = $RN-sentinel-$i"
      fi
    done
  fi | sort
  if [ "$mode" = standalone ]; then
    SIZE=1
    echo "DNS.$((SIZE)) = $RN"
    echo "DNS.$((SIZE + 1)) = $RN.$NS"
    echo "DNS.$((SIZE + 2)) = $RN.$NS.svc"
  elif [ "$mode" = cluster ]; then
    echo "DNS.$((SIZE * 2)) = $RN-leader"
    echo "DNS.$((SIZE * 2 + 1)) = $RN-leader.$NS"
    echo "DNS.$((SIZE * 2 + 2)) = $RN-leader.$NS.svc"
    echo "DNS.$((SIZE * 2 + 3)) = $RN-follower"
    echo "DNS.$((SIZE * 2 + 4)) = $RN-follower.$NS"
    echo "DNS.$((SIZE * 2 + 5)) = $RN-follower.$NS.svc"
  elif [ "$mode" = replication ]; then
    echo "DNS.$((SIZE)) = $RN"
    echo "DNS.$((SIZE + 1)) = $RN.$NS"
    echo "DNS.$((SIZE + 2)) = $RN.$NS.svc"
  elif [ "$mode" = sentinel ]; then
    echo "DNS.$((SIZE)) = $RN-sentinel"
    echo "DNS.$((SIZE + 1)) = $RN-sentinel.$NS"
    echo "DNS.$((SIZE + 2)) = $RN-sentinel.$NS.svc"
  fi
)
EOF
[ -s tls/ca.key ] || openssl genrsa -out tls/ca.key 4096
[ -s tls/ca.crt ] || openssl req \
  -x509 -new -nodes -sha256 \
  -key tls/ca.key \
  -days 3650 \
  -subj '/O=Redis/CN=Certificate Authority' \
  -out tls/ca.crt
[ -s tls/tls.key ] || openssl genrsa -out tls/tls.key 4096
openssl req \
  -new -sha256 \
  -subj "/O=RedisOperator/CN=OpenSSL" \
  -key tls/tls.key | openssl x509 -extensions v3_req -extfile "openssl.conf" \
  -req -sha256 \
  -CA tls/ca.crt \
  -CAkey tls/ca.key \
  -CAcreateserial \
  -days 3650 \
  -out tls/tls.crt

grep DNS. "openssl.conf"
rm "openssl.conf"

if kubectl create secret tls redis --cert tls/tls.crt --key tls/tls.key -oyaml --dry-run=client >/dev/null; then
  [ -s tls/tls.dh ] || openssl dhparam -out tls/tls.dh 4096
  {
    echo ---
    kubectl -n "$NS" create secret generic "redis-tls.$mode.$RN" $(for i in tls/*; do [ -s "$i" ] && echo "--from-file $i"; done | xargs) -oyaml --dry-run=client
    echo 'type: kubernetes.io/tls'
  } >"$manifest"
fi
