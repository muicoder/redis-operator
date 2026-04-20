package status

type RedisReplicationState string

const (
	ReadyReplicationReason        string = "RedisReplication is ready"
	InitializingReplicationReason string = "RedisReplication is initializing"
	FailedReplicationReason       string = "RedisReplication is Failed"
)

// Status Field of the Redis Replication
const (
	RedisReplicationReady        RedisReplicationState = "Ready"
	RedisReplicationInitializing RedisReplicationState = "Initializing"
	RedisReplicationFailed       RedisReplicationState = "Failed"
)
