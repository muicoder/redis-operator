package v1beta1

import (
	"github.com/OT-CONTAINER-KIT/redis-operator/api/status"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type RedisReplicationSpec struct {
	Size               *int32                     `json:"clusterSize"`
	KubernetesConfig   KubernetesConfig           `json:"kubernetesConfig"`
	RedisExporter      *RedisExporter             `json:"redisExporter,omitempty"`
	RedisConfig        *RedisConfig               `json:"redisConfig,omitempty"`
	Storage            *Storage                   `json:"storage,omitempty"`
	NodeSelector       map[string]string          `json:"nodeSelector,omitempty"`
	SecurityContext    *corev1.PodSecurityContext `json:"securityContext,omitempty"`
	PriorityClassName  string                     `json:"priorityClassName,omitempty"`
	Affinity           *corev1.Affinity           `json:"affinity,omitempty"`
	Tolerations        *[]corev1.Toleration       `json:"tolerations,omitempty"`
	TLS                *TLSConfig                 `json:"TLS,omitempty"`
	ReadinessProbe     *corev1.Probe              `json:"readinessProbe,omitempty" protobuf:"bytes,11,opt,name=readinessProbe"`
	LivenessProbe      *corev1.Probe              `json:"livenessProbe,omitempty" protobuf:"bytes,12,opt,name=livenessProbe"`
	Sidecars           *[]Sidecar                 `json:"sidecars,omitempty"`
	ServiceAccountName *string                    `json:"serviceAccountName,omitempty"`
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
