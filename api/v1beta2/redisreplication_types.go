package v1beta2

import (
	common "github.com/OT-CONTAINER-KIT/redis-operator/api"
	"github.com/OT-CONTAINER-KIT/redis-operator/api/status"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type RedisReplicationSpec struct {
	Size                          *int32                            `json:"clusterSize"`
	KubernetesConfig              KubernetesConfig                  `json:"kubernetesConfig"`
	RedisExporter                 *RedisExporter                    `json:"redisExporter,omitempty"`
	RedisConfig                   *RedisConfig                      `json:"redisConfig,omitempty"`
	Storage                       *Storage                          `json:"storage,omitempty"`
	NodeSelector                  map[string]string                 `json:"nodeSelector,omitempty"`
	PodSecurityContext            *corev1.PodSecurityContext        `json:"podSecurityContext,omitempty"`
	SecurityContext               *corev1.SecurityContext           `json:"securityContext,omitempty"`
	PriorityClassName             string                            `json:"priorityClassName,omitempty"`
	Affinity                      *corev1.Affinity                  `json:"affinity,omitempty"`
	Tolerations                   *[]corev1.Toleration              `json:"tolerations,omitempty"`
	TLS                           *TLSConfig                        `json:"TLS,omitempty"`
	PodDisruptionBudget           *common.RedisPodDisruptionBudget  `json:"pdb,omitempty"`
	ACL                           *ACLConfig                        `json:"acl,omitempty"`
	ReadinessProbe                *corev1.Probe                     `json:"readinessProbe,omitempty" protobuf:"bytes,11,opt,name=readinessProbe"`
	LivenessProbe                 *corev1.Probe                     `json:"livenessProbe,omitempty" protobuf:"bytes,12,opt,name=livenessProbe"`
	InitContainer                 *InitContainer                    `json:"initContainer,omitempty"`
	Sidecars                      *[]Sidecar                        `json:"sidecars,omitempty"`
	ServiceAccountName            *string                           `json:"serviceAccountName,omitempty"`
	TerminationGracePeriodSeconds *int64                            `json:"terminationGracePeriodSeconds,omitempty" protobuf:"varint,4,opt,name=terminationGracePeriodSeconds"`
	EnvVars                       *[]corev1.EnvVar                  `json:"env,omitempty"`
	TopologySpreadConstrains      []corev1.TopologySpreadConstraint `json:"topologySpreadConstraints,omitempty"`
	HostPort                      *int                              `json:"hostPort,omitempty"`
}

func (cr *RedisReplicationSpec) GetReplicationCounts(t string) int32 {
	replica := cr.Size
	return *replica
}

// RedisStatus defines the observed state of Redis
type RedisReplicationStatus struct {
	MasterNode string                       `json:"masterNode,omitempty"`
	State      status.RedisReplicationState `json:"state,omitempty"`
	Reason     string                       `json:"reason,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:storageversion
// +kubebuilder:printcolumn:name="ClusterSize",type=integer,JSONPath=`.spec.clusterSize`,description=Current cluster node count
// +kubebuilder:printcolumn:name="Master",type="string",JSONPath=".status.masterNode"
// +kubebuilder:printcolumn:name="State",type="string",JSONPath=".status.state",description="The current state of the Redis Replication",priority=1
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
// +kubebuilder:printcolumn:name="Reason",type="string",JSONPath=".status.reason",description="The reason for the current state",priority=1

// Redis is the Schema for the redis API
type RedisReplication struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   RedisReplicationSpec   `json:"spec"`
	Status RedisReplicationStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// RedisList contains a list of Redis
type RedisReplicationList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []RedisReplication `json:"items"`
}

//nolint:gochecknoinits
func init() {
	SchemeBuilder.Register(&RedisReplication{}, &RedisReplicationList{})
}
