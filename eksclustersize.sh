#!/bin/bash

echo "=== EKS Cluster Sizing Report ==="
echo "Generated: $(date)"
echo ""

# Cluster info
echo "--- Cluster Information ---"
kubectl cluster-info
echo ""

# Node information
echo "--- Node Configuration ---"
kubectl get nodes -o custom-columns="NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.node\.kubernetes\.io/instance-type,CPU-CAPACITY:.status.capacity.cpu,CPU-ALLOCATABLE:.status.allocatable.cpu,MEMORY-CAPACITY:.status.capacity.memory,ARCH:.status.nodeInfo.architecture,ZONE:.metadata.labels.topology\.kubernetes\.io/zone" --sort-by=.metadata.labels.node\.kubernetes\.io/instance-type
echo ""

# Node counts by instance type
echo "--- Node Count by Instance Type ---"
kubectl get nodes -o jsonpath='{.items[*].metadata.labels.node\.kubernetes\.io/instance-type}' | tr ' ' '\n' | sort | uniq -c | sort -nr
echo ""

# Total cluster capacity
echo "--- Total Cluster Capacity ---"
kubectl get nodes -o json | jq -r '.items | reduce .[] as $node (
  {cpu_cap: 0, cpu_alloc: 0, mem_cap: 0, mem_alloc: 0}; 
  {
    cpu_cap: (.cpu_cap + ($node.status.capacity.cpu | tonumber)),
    cpu_alloc: (.cpu_alloc + ($node.status.allocatable.cpu | tonumber)),
    mem_cap: (.mem_cap + (($node.status.capacity.memory | rtrimstr("Ki")) | tonumber)),
    mem_alloc: (.mem_alloc + (($node.status.allocatable.memory | rtrimstr("Ki")) | tonumber))
  }
) | "CPU Capacity: \(.cpu_cap) cores\nCPU Allocatable: \(.cpu_alloc) cores\nMemory Capacity: \(.mem_cap / 1024 / 1024 | round) GB\nMemory Allocatable: \(.mem_alloc / 1024 / 1024 | round) GB"'
echo ""

# Current resource usage
echo "--- Current Resource Usage ---"
if command -v kubectl-top &> /dev/null || kubectl top nodes &> /dev/null; then
    kubectl top nodes
else
    echo "Metrics server not installed - install with: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
fi
echo ""

# Pod distribution
echo "--- Pod Distribution ---"
kubectl get pods --all-namespaces -o wide | awk '{print $2}' | grep -v "NAME" | wc -l | xargs echo "Total Pods:"
kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}' | while read ns phase; do
    count=$(kubectl get pods -n $ns --no-headers 2>/dev/null | wc -l)
    echo "Namespace $ns: $count pods"
done
