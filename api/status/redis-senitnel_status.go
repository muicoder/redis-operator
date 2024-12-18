package status

type RedisSentinelState string

const (
	ReadySentinelReason        string = "RedisSenitnel is healthy"
	InitializingSentinelReason string = "RedisSentinel is initializing"
)

// Status Field of the Redis Senitnel
const (
	RedisSenitnelReady        RedisSentinelState = "Ready"
	RedisSentinelInitializing RedisSentinelState = "Initializing"
	//RedisSentinelFailed       RedisSentinelState = "Failed"
)
