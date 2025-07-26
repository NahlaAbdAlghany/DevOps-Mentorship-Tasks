
# Argocd
## ArgoCD High Availability Deployment with Kustomize

## prerequisites


 - ### install Kustomize
```sh
# Download and install the latest version
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# Move to a directory in your PATH
sudo mv kustomize /usr/local/bin/

# Verify installation
kustomize version
```
  ### Add more than worker node to the k8s cluster
 1-  in controle plane generate join token and command
 ```sh 
kubeadm token create --print-join-command
 ```
2- Add the hostname and ip of master node in hosts file  `/etc/hosts` in worker node 
3- On the worker node, run the  output command from Step 1

## Argocd HA Deploy
- copy  [ha/install.yaml](https://github.com/argoproj/argo-cd/blob/master/manifests/ha/install.yaml) in your repo under base/ and create kustomization file. 
```sh
kustomize build base/ 
kubectl apply -k base/
```
- create loadbalancer svc using [metallb](https://metallb.io/) and kustomization file under `overlayes/dev`
- I used nginx to reverse the proxy of the loadbalncer svc like that `https://external-ip:port`
now I can access argocd UI.

## Argocd-Projects 
- from UI i created `default` project that accept * namespaces and for metallb created custom project with cluster permissions [cluster-app-project.yaml](https://github.com/NahlaAbdAlghany/DevOps-Mentorship-Tasks/blob/main/argocd/argocd-apps/wordpress-app/cluster-app-project.yaml). 
- create application for each app [argocd-aap/](https://github.com/NahlaAbdAlghany/DevOps-Mentorship-Tasks/tree/main/argocd/argocd-apps/wordpress-app)
 ```sh
 kubectl apply -f argocd-app/wordpress-app/
 ```


## Links and Resources:
- [Argocd Documentation](https://argo-cd.readthedocs.io/en/release-2.5/operator-manual/installation/)
- [How to install argocd in K8s cluster](https://www.youtube.com/watch?v=NI7rPEN6bGA&t=233s)




