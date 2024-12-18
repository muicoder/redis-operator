package k8sutils

import (
	"context"
	"reflect"

	"github.com/OT-CONTAINER-KIT/redis-operator/api/status"
	redisv1beta2 "github.com/OT-CONTAINER-KIT/redis-operator/api/v1beta2"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

func UpdateRedisStandaloneStatus(ctx context.Context, cr *redisv1beta2.Redis, status status.RedisStandaloneState, resaon string) error {
	cr.Status.State = status
	cr.Status.Reason = resaon

	client, err := GenerateK8sDynamicClient(GenerateK8sConfig())
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to generate k8s dynamic client")
		return err
	}
	gvr := schema.GroupVersionResource{
		Group:    redisv1beta2.GroupVersion.Group,
		Version:  redisv1beta2.GroupVersion.Version,
		Resource: "redis",
	}
	unstructuredObj, err := runtime.DefaultUnstructuredConverter.ToUnstructured(cr)
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to convert CR to unstructured object")
		return err
	}
	unstructuredRedisStandalone := &unstructured.Unstructured{Object: unstructuredObj}

	_, err = client.Resource(gvr).Namespace(cr.Namespace).UpdateStatus(context.TODO(), unstructuredRedisStandalone, metav1.UpdateOptions{})
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to update status")
		return err
	}
	return nil
}

// UpdateRedisClusterStatus will update the status of the RedisCluster
func UpdateRedisClusterStatus(ctx context.Context, cr *redisv1beta2.RedisCluster, state status.RedisClusterState, reason string, readyLeaderReplicas, readyFollowerReplicas int32, dcl dynamic.Interface) error {
	newStatus := redisv1beta2.RedisClusterStatus{
		State:                 state,
		Reason:                reason,
		ReadyLeaderReplicas:   readyLeaderReplicas,
		ReadyFollowerReplicas: readyFollowerReplicas,
	}
	if reflect.DeepEqual(cr.Status, newStatus) {
		return nil
	}
	cr.Status = newStatus
	gvr := schema.GroupVersionResource{
		Group:    redisv1beta2.GroupVersion.Group,
		Version:  redisv1beta2.GroupVersion.Version,
		Resource: "redisclusters",
	}
	unstructuredObj, err := runtime.DefaultUnstructuredConverter.ToUnstructured(cr)
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to convert CR to unstructured object")
		return err
	}
	unstructuredRedisCluster := &unstructured.Unstructured{Object: unstructuredObj}

	_, err = dcl.Resource(gvr).Namespace(cr.Namespace).UpdateStatus(context.TODO(), unstructuredRedisCluster, metav1.UpdateOptions{})
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to update status")
		return err
	}
	return nil
}

func UpdateRedisSentinelStatus(ctx context.Context, cr *redisv1beta2.RedisSentinel, status status.RedisSentinelState, resaon string) error {
	cr.Status.State = status
	cr.Status.Reason = resaon

	client, err := GenerateK8sDynamicClient(GenerateK8sConfig())
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to generate k8s dynamic client")
		return err
	}
	gvr := schema.GroupVersionResource{
		Group:    redisv1beta2.GroupVersion.Group,
		Version:  redisv1beta2.GroupVersion.Version,
		Resource: "redissentinels",
	}
	unstructuredObj, err := runtime.DefaultUnstructuredConverter.ToUnstructured(cr)
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to convert CR to unstructured object")
		return err
	}
	unstructuredRedisSentinel := &unstructured.Unstructured{Object: unstructuredObj}

	_, err = client.Resource(gvr).Namespace(cr.Namespace).UpdateStatus(context.TODO(), unstructuredRedisSentinel, metav1.UpdateOptions{})
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to update status")
		return err
	}
	return nil
}

func UpdateRedisReplicationStatus(ctx context.Context, cr *redisv1beta2.RedisReplication, status status.RedisReplicationState, resaon string) error {
	cr.Status.State = status
	cr.Status.Reason = resaon

	client, err := GenerateK8sDynamicClient(GenerateK8sConfig())
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to generate k8s dynamic client")
		return err
	}
	gvr := schema.GroupVersionResource{
		Group:    redisv1beta2.GroupVersion.Group,
		Version:  redisv1beta2.GroupVersion.Version,
		Resource: "redisreplications",
	}
	unstructuredObj, err := runtime.DefaultUnstructuredConverter.ToUnstructured(cr)
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to convert CR to unstructured object")
		return err
	}
	unstructuredRedisReplication := &unstructured.Unstructured{Object: unstructuredObj}

	_, err = client.Resource(gvr).Namespace(cr.Namespace).UpdateStatus(context.TODO(), unstructuredRedisReplication, metav1.UpdateOptions{})
	if err != nil {
		log.FromContext(ctx).Error(err, "Failed to update status")
		return err
	}
	return nil
}
