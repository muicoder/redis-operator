package status

type RedisReplicationState string

const (
	ReadyReplicationReason        string = "RedisReplication is healthy"
	InitializingReplicationReason string = "RedisReplication is initializing"
)

// Status Field of the Redis Replication
const (
	RedisReplicationReady        RedisReplicationState = "Ready"
	RedisReplicationInitializing RedisReplicationState = "Initializing"
	// RedisReplicationFailed       RedisReplicationState = "Failed"
)
