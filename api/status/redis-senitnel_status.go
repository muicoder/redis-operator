package status

type RedisSentinelState string

const (
	ReadySentinelReason        string = "RedisSenitnel is ready"
	InitializingSentinelReason string = "RedisSentinel is initializing"
	FailedSentinelReason       string = "RedisSentinel is Failed"
)

// Status Field of the Redis Senitnel
const (
	RedisSenitnelReady        RedisSentinelState = "Ready"
	RedisSentinelInitializing RedisSentinelState = "Initializing"
	RedisSentinelFailed       RedisSentinelState = "Failed"
)
