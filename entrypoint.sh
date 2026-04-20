#!/bin/sh

set -e

readonly RedisDir="/data"
readonly EXTERNAL_MOUNT="/etc/redis/external.conf.d"

REDISCLI_AUTH="${REDIS_PASSWORD:-$REDISCLI_AUTH}"
REDIS_MAJOR_VERSION=$(redis-server --version | awk '{print $3}' | sed 's/=//' | awk -F. '{print $1}' | cut -dv -f2)

case $SERVER_MODE in
sentinel)
  readonly SERVER_PORT="${SERVER_PORT:-26379}"
  readonly RedisConf="$RedisDir/$SERVER_MODE.conf"
  ;;
*)
  readonly SERVER_PORT="${SERVER_PORT:-6379}"
  readonly RedisConf="$RedisDir/redis.conf"
  ;;
esac

cat <<EOF >"$RedisConf"
bind 0.0.0.0 ::
port $SERVER_PORT
protected-mode no
daemonize no
logfile ""
dir $RedisDir
$(
  limit_memory=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes /sys/fs/cgroup/memory.max 2>/dev/null || true)
  if [ "$limit_memory" -ge 1048576 ] && [ "$limit_memory" -le 68719476736 ]; then # 1Mi~64Gi
    echo "maxmemory $((limit_memory * 90 / 100))"
  fi
  if [ "$NODEPORT" = "true" ]; then
    echo "cluster-announce-port $(env | grep announce_port_ | awk -F= '{print $NF}')"
    echo "cluster-announce-bus-port $(env | grep announce_bus_port_ | awk -F= '{print $NF}')"
  fi
)
EOF

redis_conf() {
  # auth
  if [ -n "$REDISCLI_AUTH" ]; then
    {
      echo "masterauth $REDISCLI_AUTH"
      echo "requirepass $REDISCLI_AUTH"
    } >>"$RedisConf"
  else
    echo "running without password which is not recommended"
  fi
  # cluster
  if [ "$SERVER_MODE" = "cluster" ]; then
    {
      echo "cluster-config-file $RedisDir/nodes.conf"
      echo "cluster-enabled yes"
      echo "cluster-migration-barrier 1"
      echo "cluster-node-timeout 5000"
      echo "cluster-require-full-coverage no"
    } >>"$RedisConf"
  fi
  # aof
  if [ -n "$PERSISTENCE_ENABLED" ]; then
    {
      echo "appendonly yes"
    } >>"$RedisConf"
  else
    echo "Running without persistence mode"
  fi
}

sentinel_conf() {
  # auth
  if [ -n "$REDISCLI_AUTH" ]; then
    if [ "$REDIS_MAJOR_VERSION" -ge 6 ]; then
      case $REDIS_MAJOR_VERSION in
      7)
        echo "sentinel sentinel-pass $REDISCLI_AUTH"
        ;;
      6)
        echo "requirepass $REDISCLI_AUTH"
        ;;
      esac >>"$RedisConf"
    else
      echo "running with password provided but not supported by redis v$REDIS_MAJOR_VERSION.y.z"
    fi
  else
    echo "running without password which is not recommended"
  fi
  # replication
  readonly REPLSVC="${REPLICATION:-repl}"
  readonly MONITOR="${MASTER_GROUP_NAME:-mymaster}"
  REPL_AUTH=$(
    grep "sentinel auth-pass " -r "$EXTERNAL_MOUNT" | grep .conf: | awk -F: '{print $NF}' | sort | uniq |
      grep "sentinel auth-pass " | awk '{print $NF}' || echo "$MASTER_PASSWORD"
  )
  if [ -n "$REPL_AUTH" ]; then
    export REDISCLI_AUTH="$REPL_AUTH"
  fi
  if [ -s "$REDIS_TLS_CA_KEY" ] && [ "$REDIS_MAJOR_VERSION" -ge 6 ]; then
    readonly REDIS_CLI="redis-cli --tls --cacert $REDIS_TLS_CA_KEY"
  else
    readonly REDIS_CLI="redis-cli"
  fi
  until $REDIS_CLI -h "$MASTER_HOST" -p "$MASTER_PORT" info Keyspace 2>/dev/null; do
    eval "$($REDIS_CLI -h "$REPLSVC" -p "$MASTER_PORT" info Replication 2>/dev/null | grep "master_[hp]o[rs]t:" | awk -F: '{sub("\r$", "");printf("%s=%s\n"),toupper($1),$2}')"
    sleep 1
  done
  {
    echo "sentinel monitor $MONITOR ${IP:-$MASTER_HOST} ${PORT:-$MASTER_PORT} ${QUORUM:-2}"
    if [ -n "$REDISCLI_AUTH" ]; then
      echo "sentinel auth-pass $MONITOR $REDISCLI_AUTH"
    fi
    echo "sentinel down-after-milliseconds $MONITOR ${DOWN_AFTER_MILLISECONDS:-30000}"
    echo "sentinel parallel-syncs $MONITOR ${PARALLEL_SYNCS:-1}"
    echo "sentinel failover-timeout $MONITOR ${FAILOVER_TIMEOUT:-180000}"
    echo "SENTINEL resolve-hostnames ${RESOLVE_HOSTNAMES:-no}"
    echo "SENTINEL announce-hostnames ${ANNOUNCE_HOSTNAMES:-no}"
    if [ -n "${SENTINEL_ID}" ]; then
      printf "sentinel myid %s\n" "$(echo "$SENTINEL_ID" | sha1sum | awk '{print $1}')"
    fi
  } >>"$RedisConf"
}

case $SERVER_MODE in
sentinel)
  sentinel_conf
  ;;
*)
  redis_conf
  ;;
esac

EXTERNAL_CONFIG="$(find "$EXTERNAL_MOUNT" -type f | sort | grep .conf$ 2>/dev/null || true)"
if [ -n "$EXTERNAL_CONFIG" ]; then
  sed -i "/include/d" "$RedisConf"
  for EXTERNAL_CONF in $EXTERNAL_CONFIG; do
    echo "include $EXTERNAL_MOUNT/${EXTERNAL_CONF##*/}"
  done >>"$RedisConf"
fi

if [ -n "$TLS_MODE" ] && [ "$REDIS_MAJOR_VERSION" -ge 6 ]; then
  {
    echo "port 0"
    echo "tls-port $SERVER_PORT"
    echo "tls-cert-file $REDIS_TLS_CERT"
    echo "tls-key-file $REDIS_TLS_CERT_KEY"
    echo "tls-ca-cert-file $REDIS_TLS_CA_KEY"
    echo "tls-prefer-server-ciphers no"
    echo "tls-auth-clients optional"
    if [ -s "${REDIS_TLS_CERT%.*}.dh" ]; then
      echo "tls-dh-params-file ${REDIS_TLS_CERT%.*}.dh"
    fi
    if [ "$SERVER_MODE" = "cluster" ]; then
      echo "tls-cluster yes"
      case $REDIS_MAJOR_VERSION in
      7)
        echo "cluster-preferred-endpoint-type hostname"
        ;;
      esac
    fi
    if [ "$SERVER_MODE" != "standalone" ]; then
      echo "tls-replication yes"
    fi
  } >>"$RedisConf"
else
  echo "Running without TLS mode"
fi

if [ "$ACL_MODE" = "true" ]; then
  echo "aclfile /etc/redis/user.acl" >>"$RedisConf"
else
  echo "ACL_MODE is not true, skipping ACL file modification"
fi

find "$RedisDir" ! -user redis -exec chown redis '{}' +

##### Starting redis service

echo "Starting redis service in $SERVER_MODE mode.....One"
if command -v gosu >/dev/null 2>&1; then
  readonly SU="gosu redis"
elif command -v su-exec >/dev/null 2>&1; then
  readonly SU="su-exec redis"
else
  readonly SU=""
fi

echo "Starting redis service in $SERVER_MODE mode.....Two"
# https://github.com/redis/redis/blob/unstable/utils/systemd-redis_server.service
umask 0077

echo "Starting redis service in $SERVER_MODE mode.....Three"
case $SERVER_MODE in
cluster)
  POD_IP=$(hostname -I | awk '{print $1}')
  if [ -s "$RedisDir/nodes.conf" ]; then
    sed -i -E "/myself/s/ [0-9.]+:/ $POD_IP:/" "$RedisDir/nodes.conf"
  fi
  case $REDIS_MAJOR_VERSION in
  7)
    exec $SU redis-server "$RedisConf" --cluster-announce-ip "$POD_IP" --cluster-announce-hostname "$(hostname)"
    ;;
  *)
    exec $SU redis-server "$RedisConf" --cluster-announce-ip "$POD_IP"
    ;;
  esac
  ;;
sentinel)
  exec $SU redis-server "$RedisConf" --sentinel
  ;;
*)
  exec $SU redis-server "$RedisConf"
  ;;
esac
