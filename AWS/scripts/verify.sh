#!/bin/bash

# RocketChat EKS Verification Script
# This script verifies the deployment and provides status information

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check cluster connectivity
check_cluster() {
    print_status "Checking cluster connectivity..."
    
    if kubectl cluster-info &> /dev/null; then
        print_success "Cluster is accessible"
    else
        print_error "Cannot connect to cluster. Please check kubectl configuration."
        exit 1
    fi
}

# Check nodes
check_nodes() {
    print_status "Checking EKS nodes..."
    
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    READY_NODES=$(kubectl get nodes --no-headers | grep "Ready" | wc -l)
    
    echo "Total nodes: $NODE_COUNT"
    echo "Ready nodes: $READY_NODES"
    
    if [ "$NODE_COUNT" -eq "$READY_NODES" ] && [ "$NODE_COUNT" -gt 0 ]; then
        print_success "All nodes are ready"
    else
        print_error "Some nodes are not ready"
        kubectl get nodes
    fi
}

# Check RocketChat deployment
check_rocketchat() {
    print_status "Checking RocketChat deployment..."
    
    # Check pods
    ROCKETCHAT_PODS=$(kubectl get pods -n rocketchat --no-headers | wc -l)
    ROCKETCHAT_READY=$(kubectl get pods -n rocketchat --no-headers | grep "Running" | wc -l)
    
    echo "RocketChat pods: $ROCKETCHAT_PODS"
    echo "Ready pods: $ROCKETCHAT_READY"
    
    if [ "$ROCKETCHAT_PODS" -eq "$ROCKETCHAT_READY" ] && [ "$ROCKETCHAT_PODS" -gt 0 ]; then
        print_success "RocketChat pods are running"
    else
        print_error "Some RocketChat pods are not running"
        kubectl get pods -n rocketchat
    fi
    
    # Check services
    kubectl get services -n rocketchat
    
    # Check ingress
    kubectl get ingress -n rocketchat
}

# Check MongoDB
check_mongodb() {
    print_status "Checking MongoDB deployment..."
    
    # Check pods
    MONGODB_PODS=$(kubectl get pods -n rocketchat -l app.kubernetes.io/name=mongodb --no-headers | wc -l)
    MONGODB_READY=$(kubectl get pods -n rocketchat -l app.kubernetes.io/name=mongodb --no-headers | grep "Running" | wc -l)
    
    echo "MongoDB pods: $MONGODB_PODS"
    echo "Ready pods: $MONGODB_READY"
    
    if [ "$MONGODB_PODS" -eq "$MONGODB_READY" ] && [ "$MONGODB_PODS" -gt 0 ]; then
        print_success "MongoDB pods are running"
    else
        print_error "Some MongoDB pods are not running"
        kubectl get pods -n rocketchat -l app.kubernetes.io/name=mongodb
    fi
}

# Check monitoring stack
check_monitoring() {
    print_status "Checking monitoring stack..."
    
    # Check Prometheus
    PROMETHEUS_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | wc -l)
    PROMETHEUS_READY=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | grep "Running" | wc -l)
    
    echo "Prometheus pods: $PROMETHEUS_PODS"
    echo "Ready pods: $PROMETHEUS_READY"
    
    if [ "$PROMETHEUS_PODS" -eq "$PROMETHEUS_READY" ] && [ "$PROMETHEUS_PODS" -gt 0 ]; then
        print_success "Prometheus is running"
    else
        print_error "Prometheus is not running"
        kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
    fi
    
    # Check Grafana
    GRAFANA_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | wc -l)
    GRAFANA_READY=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | grep "Running" | wc -l)
    
    echo "Grafana pods: $GRAFANA_PODS"
    echo "Ready pods: $GRAFANA_READY"
    
    if [ "$GRAFANA_PODS" -eq "$GRAFANA_READY" ] && [ "$GRAFANA_PODS" -gt 0 ]; then
        print_success "Grafana is running"
    else
        print_error "Grafana is not running"
        kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
    fi
}

# Check storage
check_storage() {
    print_status "Checking storage..."
    
    # Check PVCs
    kubectl get pvc --all-namespaces
    
    # Check storage classes
    kubectl get storageclass
    
    # Check persistent volumes
    kubectl get pv
}

# Check load balancer
check_load_balancer() {
    print_status "Checking load balancer..."
    
    # Get ALB DNS name
    ALB_DNS=$(kubectl get ingress -n rocketchat -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available")
    
    if [ "$ALB_DNS" != "Not available" ] && [ -n "$ALB_DNS" ]; then
        print_success "Load balancer DNS: $ALB_DNS"
        
        # Test connectivity
        if curl -s --connect-timeout 10 "http://$ALB_DNS" > /dev/null; then
            print_success "RocketChat is accessible via load balancer"
        else
            print_warning "RocketChat is not accessible via load balancer (may still be starting)"
        fi
    else
        print_error "Load balancer not found"
    fi
}

# Check resource usage
check_resources() {
    print_status "Checking resource usage..."
    
    # Node resources
    echo "Node resource usage:"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    
    # Pod resources
    echo "Pod resource usage:"
    kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics server not available"
}

# Check events
check_events() {
    print_status "Checking recent events..."
    
    # Get recent events
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
}

# Generate report
generate_report() {
    print_status "Generating verification report..."
    
    REPORT_FILE="verification-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "RocketChat EKS Verification Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo ""
        
        echo "Cluster Information:"
        kubectl cluster-info
        echo ""
        
        echo "Node Status:"
        kubectl get nodes
        echo ""
        
        echo "RocketChat Status:"
        kubectl get pods -n rocketchat
        echo ""
        
        echo "MongoDB Status:"
        kubectl get pods -n rocketchat -l app.kubernetes.io/name=mongodb
        echo ""
        
        echo "Monitoring Status:"
        kubectl get pods -n monitoring
        echo ""
        
        echo "Services:"
        kubectl get services --all-namespaces
        echo ""
        
        echo "Ingress:"
        kubectl get ingress --all-namespaces
        echo ""
        
        echo "Storage:"
        kubectl get pvc --all-namespaces
        echo ""
        
        echo "Recent Events:"
        kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10
        echo ""
        
    } > "$REPORT_FILE"
    
    print_success "Verification report saved to: $REPORT_FILE"
}

# Main verification function
main() {
    echo "🔍 Starting RocketChat EKS Verification..."
    echo ""
    
    check_cluster
    check_nodes
    check_rocketchat
    check_mongodb
    check_monitoring
    check_storage
    check_load_balancer
    check_resources
    check_events
    generate_report
    
    print_success "🎉 Verification completed!"
}

# Run main function
main "$@"
