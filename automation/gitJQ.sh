# Quick node info
kubectl get nodes -o custom-columns="NAME:.metadata.name,TYPE:.metadata.labels.node\.kubernetes\.io/instance-type,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory"

# Just the numbers
echo "Nodes: $(kubectl get nodes --no-headers | wc -l), CPU: $(kubectl get nodes -o jsonpath='{.items[*].status.capacity.cpu}' | tr ' ' '\n' | awk '{sum+=$1} END {print sum}') cores"

# Memory per instance type
kubectl get nodes -o json | jq -r '.items | group_by(.metadata.labels."node.kubernetes.io/instance-type")[] | {type: .[0].metadata.labels."node.kubernetes.io/instance-type", count: length, memory: .[0].status.capacity.memory} | "\(.type) x \(.count): \(.memory)"'




echo "=== Memory to GB Conversion ==="
kubectl get nodes -o json | jq -r '.items[] | 
  .metadata.name + " | " + 
  .metadata.labels."node.kubernetes.io/instance-type" + " | " + 
  .status.capacity.memory + " -> " + 
  (
    if .status.capacity.memory | endswith("Ki") then
      "\((.status.capacity.memory | rtrimstr("Ki") | tonumber) / 1024 / 1024 | round) GB"
    elif .status.capacity.memory | endswith("Mi") then
      "\((.status.capacity.memory | rtrimstr("Mi") | tonumber) / 1024 | round) GB"
    elif .status.capacity.memory | endswith("Gi") then
      "\(.status.capacity.memory | rtrimstr("Gi") | tonumber) GB"
    else
      .status.capacity.memory
    end
  )'
