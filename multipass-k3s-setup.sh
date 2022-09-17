# create node names
export K3S_MASTER_NODE_NAME=k3s-master
export K3S_WORKER_NODE1_NAME=k3s-node1
export K3S_WORKER_NODE2_NAME=k3s-node2

# create nodes
multipass launch --name $K3S_MASTER_NODE_NAME --cpus 1 --mem 2048M --disk 15G
multipass launch --name $K3S_WORKER_NODE1_NAME --cpus 1 --mem 2048M --disk 15G
# multipass launch --name $K3S_WORKER_NODE2_NAME --cpus 1 --mem 1024M --disk 3G

# get IP of master node
export K3S_MASTER_IP=$(multipass list --format json | jq ".list[] | select(.name==\"$K3S_MASTER_NODE_NAME\") | .ipv4[]" | cut -d '"' -f 2)

# install k3s on master
multipass exec $K3S_MASTER_NODE_NAME -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -"

## get node token from master node
export K3S_TOKEN=$(multipass exec $K3S_MASTER_NODE_NAME -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")

# install k3s on worker nodes
multipass exec $K3S_WORKER_NODE1_NAME -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=https://${K3S_MASTER_IP}:6443 sh -"
# multipass exec $K3S_WORKER_NODE2_NAME -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=https://${K3S_MASTER_IP}:6443 sh -"

# copy config from master to local machine
multipass exec $K3S_MASTER_NODE_NAME -- /bin/bash -c "cat /etc/rancher/k3s/k3s.yaml" | sed "s/127.0.0.1/$K3S_MASTER_IP/" > ~/.kube/config
sudo chmod 600 ~/.kube/config 

# install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml