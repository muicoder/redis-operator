/*
Copyright 2020 Opstree Solutions.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package redis

import (
	"context"
	"time"

	"github.com/OT-CONTAINER-KIT/redis-operator/api/status"
	redisv1beta2 "github.com/OT-CONTAINER-KIT/redis-operator/api/v1beta2"
	intctrlutil "github.com/OT-CONTAINER-KIT/redis-operator/pkg/controllerutil"
	"github.com/OT-CONTAINER-KIT/redis-operator/pkg/k8sutils"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

// Reconciler reconciles a Redis object
type Reconciler struct {
	client.Client
	K8sClient  kubernetes.Interface
	Dk8sClient dynamic.Interface
}

func (r *Reconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	instance := &redisv1beta2.Redis{}

	err := r.Client.Get(context.TODO(), req.NamespacedName, instance)
	if err != nil {
		return intctrlutil.RequeueWithErrorChecking(ctx, err, "failed to get redis instance")
	}
	if instance.ObjectMeta.GetDeletionTimestamp() != nil {
		if err = k8sutils.HandleRedisFinalizer(ctx, r.Client, instance); err != nil {
			return intctrlutil.RequeueWithError(ctx, err, "failed to handle redis finalizer")
		}
		return intctrlutil.Reconciled()
	}
	if _, err := r.K8sClient.CoreV1().ConfigMaps(instance.Namespace).Get(context.TODO(), "entrypoint."+redisv1beta2.GroupVersion.Group, metav1.GetOptions{}); err != nil {
		return intctrlutil.RequeueWithError(ctx, err, "failed to get redis ConfigMap entrypoint."+redisv1beta2.GroupVersion.Group)
	}
	if _, found := instance.ObjectMeta.GetAnnotations()[redisv1beta2.GroupVersion.Group+"/skip-reconcile"]; found {
		return intctrlutil.RequeueAfter(ctx, time.Second*10, "found skip reconcile annotation")
	}
	if err = k8sutils.AddFinalizer(ctx, instance, k8sutils.RedisFinalizer, r.Client); err != nil {
		return intctrlutil.RequeueWithError(ctx, err, "failed to add finalizer")
	}
	err = k8sutils.CreateStandaloneRedis(ctx, instance, r.K8sClient)
	if err != nil {
		return intctrlutil.RequeueWithError(ctx, err, "failed to create redis")
	}
	err = k8sutils.CreateStandaloneService(ctx, instance, r.K8sClient)
	if err != nil {
		return intctrlutil.RequeueWithError(ctx, err, "failed to create service")
	}
	sts, err := r.K8sClient.AppsV1().StatefulSets(instance.Namespace).Get(context.TODO(), instance.Name, metav1.GetOptions{})
	if err == nil {
		if sts.Status.ReadyReplicas == 1 {
			instance.Status.State = status.RedisStandaloneReady
			instance.Status.Reason = status.ReadyStandaloneReason
		} else {
			instance.Status.State = status.RedisStandaloneInitializing
			instance.Status.Reason = status.InitializingStandaloneReason
		}
	} else {
		instance.Status.State = status.RedisStandaloneFailed
		instance.Status.Reason = status.FailedStandaloneReason
	}
	r.Client.Status().Update(ctx, instance)
	return intctrlutil.RequeueAfter(ctx, time.Second*10, "requeue after 10 seconds")
}

// SetupWithManager sets up the controller with the Manager.
func (r *Reconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&redisv1beta2.Redis{}).
		Complete(r)
}
