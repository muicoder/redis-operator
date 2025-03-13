package k8sutils

const (
	AnnotationKeyRecreateStatefulset         = "redis/recreate-statefulset"
	AnnotationKeyRecreateStatefulsetStrategy = "redis/recreate-statefulset-strategy"
)

const (
	EnvOperatorSTSPVCTemplateName = "OPERATOR_STS_PVC_TEMPLATE_NAME"
)

const (
	RedisRoleLabelKey    = "redis-role"
	RedisRoleLabelMaster = "master"
	RedisRoleLabelSlave  = "slave"
)
