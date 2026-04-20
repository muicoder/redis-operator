#!/bin/sh

set -e

cd "$(dirname "$0")" >/dev/null || exit

readonly NS="${1:-redis}"      # Namespace for kubernetes
readonly RN="${2:-redis}"      # ReleaseName for helm
readonly TLS_MODE="${3:-none}" # enabled TLS

if [ $# -eq 0 ]; then
  cat <<EOF
README:
  sh $0 Namespace(is $NS) ReleaseName(is $RN) [TLS_MODE(is $TLS_MODE)]
eg:
  sh $0 $NS $RN [$TLS_MODE]
EOF
  exit
fi

cat <<EOF >"Chart.yaml"
apiVersion: v2
appVersion: '6.2'
description: Provides easy redis setup definitions for Kubernetes services, and deployment.
name: redis
version: 1.0.0
EOF

for mode in standalone cluster replication sentinel; do
  if [ "$TLS_MODE" != "none" ]; then
    case $mode in
    replication)
      sh gen-tls.sh "$NS" "$RN-repl" "$mode" "manifest.$mode.$RN.yaml"
      tlsSecret=",tlsSecretName=redis-tls.$mode.$RN-repl"
      ;;
    *)
      sh gen-tls.sh "$NS" "$RN" "$mode" "manifest.$mode.$RN.yaml"
      tlsSecret=",tlsSecretName=redis-tls.$mode.$RN"
      ;;
    esac
  else
    echo >"manifest.$mode.$RN.yaml"
  fi
  case $mode in
  replication)
    helm -n "$NS" template "$RN-repl" . --set "mode=$mode$tlsSecret" >>"manifest.$mode.$RN.yaml"
    ;;
  sentinel)
    helm -n "$NS" template "$RN" . --set "mode=$mode$tlsSecret,repl=$RN-repl" >>"manifest.$mode.$RN.yaml"
    ;;
  *)
    helm -n "$NS" template "$RN" . --set "mode=$mode$tlsSecret" >>"manifest.$mode.$RN.yaml"
    ;;
  esac
done

# apply
ls -l "manifest."*".$RN.yaml"
cat "manifest."*".$RN.yaml" >"aio.$RN.yaml"
kubectl create -f "aio.$RN.yaml" --dry-run=client || true
echo
echo "Standalone:  $RN.$NS.svc"
echo "Replication: $RN-repl.$NS.svc"
echo "Sentinel:    $RN-sentinel.$NS.svc"
echo "Cluster:     $RN-leader.$NS.svc OR $RN-follower.$NS.svc"
echo
echo "kubectl apply -f $PWD/aio.$RN.yaml"
echo
