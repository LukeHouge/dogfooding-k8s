#!/bin/bash

# Microservices Autoscaling Demo Script
# This script demonstrates queue-based autoscaling with Redis and Dramatiq

set -e

# Configuration
FASTAPI_URL="http://localhost:30082"
NAMESPACE="microservices"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if FastAPI is accessible
check_fastapi() {
    print_step "Checking FastAPI accessibility..."
    if curl -s "$FASTAPI_URL/health" > /dev/null; then
        print_info "FastAPI is accessible at $FASTAPI_URL"
    else
        print_error "FastAPI not accessible at $FASTAPI_URL"
        print_warning "Make sure to port-forward: kubectl port-forward -n $NAMESPACE svc/fastapi-app 30082:80"
        exit 1
    fi
}

# Monitor function
monitor_system() {
    local duration=$1
    local end_time=$((SECONDS + duration))
    
    print_step "Monitoring system for ${duration}s..."
    
    while [ $SECONDS -lt $end_time ]; do
        echo "=================================================="
        echo "Time: $(date '+%H:%M:%S')"
        
        # Get queue stats
        queue_stats=$(curl -s "$FASTAPI_URL/api/queue-stats" || echo '{"queue_length": "N/A", "error": "API unreachable"}')
        echo "Queue Stats: $queue_stats"
        
        # Get pod counts
        echo ""
        echo "Pod Status:"
        kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=dramatiq-worker --no-headers | wc -l | xargs echo "Worker Pods:"
        kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=doubler-service --no-headers | wc -l | xargs echo "Doubler Pods:"
        
        # Get HPA status
        echo ""
        echo "HPA Status:"
        kubectl get hpa -n $NAMESPACE --no-headers 2>/dev/null || echo "HPA not available"
        
        echo "=================================================="
        sleep 10
    done
}

# Load test function
send_requests() {
    local count=$1
    local delay=$2
    
    print_step "Sending $count requests with ${delay}s delay between requests..."
    
    for i in $(seq 1 $count); do
        number=$((i * 3 + 7))  # Generate some variety in numbers
        
        task_response=$(curl -s -X POST "$FASTAPI_URL/api/queue-number" \
            -H "Content-Type: application/json" \
            -d "{\"number\": $number}")
        
        task_id=$(echo $task_response | grep -o '"task_id":"[^"]*"' | cut -d'"' -f4)
        
        print_info "Request $i/$count: Number=$number, TaskID=${task_id:0:8}..."
        
        sleep $delay
    done
}

# Demo phases
run_demo() {
    print_step "🚀 Starting Microservices Autoscaling Demo"
    echo ""
    
    # Phase 1: Initial state
    print_step "Phase 1: Checking initial state (30s)"
    monitor_system 30 &
    MONITOR_PID=$!
    
    sleep 35
    kill $MONITOR_PID 2>/dev/null || true
    
    # Phase 2: Light load
    print_step "Phase 2: Sending light load (5 requests, 3s apart)"
    send_requests 5 3 &
    monitor_system 30 &
    MONITOR_PID=$!
    
    wait
    kill $MONITOR_PID 2>/dev/null || true
    
    # Phase 3: Heavy load (triggers scaling)
    print_step "Phase 3: Sending heavy load (15 requests quickly)"
    send_requests 15 1 &
    monitor_system 60 &
    MONITOR_PID=$!
    
    wait
    kill $MONITOR_PID 2>/dev/null || true
    
    # Phase 4: Let it scale up and process
    print_step "Phase 4: Watching autoscaling in action (2 minutes)"
    monitor_system 120 &
    MONITOR_PID=$!
    
    sleep 125
    kill $MONITOR_PID 2>/dev/null || true
    
    # Phase 5: Cool down
    print_step "Phase 5: Cool down period - watching scale down (3 minutes)"
    monitor_system 180 &
    MONITOR_PID=$!
    
    sleep 185
    kill $MONITOR_PID 2>/dev/null || true
    
    print_step "✅ Demo completed!"
    
    # Final stats
    print_info "Final queue stats:"
    curl -s "$FASTAPI_URL/api/queue-stats" | jq . 2>/dev/null || curl -s "$FASTAPI_URL/api/queue-stats"
    
    print_info "Final pod counts:"
    kubectl get pods -n $NAMESPACE
}

# Interactive monitoring
interactive_monitor() {
    print_step "🔍 Interactive monitoring mode (Ctrl+C to exit)"
    
    while true; do
        clear
        echo "============== MICROSERVICES DEMO MONITOR =============="
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # Queue stats
        echo "📊 QUEUE STATISTICS:"
        queue_stats=$(curl -s "$FASTAPI_URL/api/queue-stats" 2>/dev/null || echo '{"error": "API unreachable"}')
        echo "$queue_stats" | jq . 2>/dev/null || echo "$queue_stats"
        echo ""
        
        # Pod status
        echo "🏗️  POD STATUS:"
        kubectl get pods -n $NAMESPACE -o wide 2>/dev/null || echo "Cannot access pods"
        echo ""
        
        # HPA status
        echo "📈 AUTOSCALER STATUS:"
        kubectl get hpa -n $NAMESPACE 2>/dev/null || echo "HPA not available"
        echo ""
        
        # Services
        echo "🌐 SERVICES:"
        kubectl get svc -n $NAMESPACE 2>/dev/null || echo "Cannot access services"
        echo ""
        
        echo "========================================================="
        echo "Commands:"
        echo "- Send 1 request: curl -X POST $FASTAPI_URL/api/queue-number -H 'Content-Type: application/json' -d '{\"number\": 42}'"
        echo "- Load test: curl -X POST $FASTAPI_URL/api/load-test?count=10"
        echo "- Manual scale: kubectl scale deployment dramatiq-worker --replicas=5 -n $NAMESPACE"
        
        sleep 5
    done
}

# Load test only
load_test_only() {
    local count=${1:-10}
    print_step "🔥 Load Test: Sending $count requests"
    
    curl -X POST "$FASTAPI_URL/api/load-test?count=$count" \
        -H "Content-Type: application/json" | jq . 2>/dev/null || echo "Load test sent"
    
    print_info "Monitor with: kubectl get pods -n $NAMESPACE -w"
}

# Main script
main() {
    case "${1:-demo}" in
        "demo")
            check_fastapi
            run_demo
            ;;
        "monitor")
            check_fastapi
            interactive_monitor
            ;;
        "load")
            check_fastapi
            load_test_only ${2:-10}
            ;;
        "help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  demo     - Run full autoscaling demonstration (default)"
            echo "  monitor  - Interactive monitoring mode"
            echo "  load [n] - Send load test with n requests (default: 10)"
            echo "  help     - Show this help"
            echo ""
            echo "Prerequisites:"
            echo "  - Microservices deployed to '$NAMESPACE' namespace"
            echo "  - FastAPI accessible at $FASTAPI_URL"
            echo "  - kubectl configured for the cluster"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"