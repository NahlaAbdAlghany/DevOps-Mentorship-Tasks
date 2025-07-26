
# Metallb


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

## Installation with kustomize

```sh
# kustomization.yml
namespace: metallb-system

resources:
  - github.com/metallb/metallb/config/frr?ref=v0.15.2
```
- build kustomize file 
## Configuration

## Link and resources

- [metallb-Documentation](https://metallb.io/)