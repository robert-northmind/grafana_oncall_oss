#!/bin/bash

# Script to fix Coolify deployment issues after redeploy
# The migration container gets stuck in a restart loop, preventing other services from starting

set -e

# Source environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Configuration
SERVER_IP="${SERVER_IP}"
PROJECT_ID="${COOLIFY_PROJECT_ID}"

# Check if required variables are set
if [ -z "$SERVER_IP" ]; then
    echo "❌ Error: SERVER_IP not set in .env file"
    exit 1
fi

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: COOLIFY_PROJECT_ID not set in .env file"
    exit 1
fi

echo "🔧 Fixing Coolify OnCall Deployment"
echo "==================================="

# Function to check container status
check_container() {
    local container_name=$1
    ssh root@$SERVER_IP "docker ps -a --format '{{.Names}}\t{{.Status}}' | grep $container_name | grep $PROJECT_ID" 2>/dev/null
}

# Function to wait for container
wait_for_container() {
    local container_name=$1
    local max_wait=30
    local count=0
    
    echo -n "Waiting for $container_name to appear"
    while [ $count -lt $max_wait ]; do
        if check_container "$container_name" > /dev/null; then
            echo " ✅"
            return 0
        fi
        echo -n "."
        sleep 2
        count=$((count + 1))
    done
    echo " ❌ Timeout"
    return 1
}

echo "1️⃣ Checking for stuck migration container..."

# Check if migration container exists and is restarting
MIGRATION_STATUS=$(check_container "oncall_db_migration")
if [ ! -z "$MIGRATION_STATUS" ]; then
    echo "Found migration container: $MIGRATION_STATUS"
    
    # Check if migration completed successfully
    echo "Checking migration logs..."
    MIGRATION_LOGS=$(ssh root@$SERVER_IP "docker logs oncall_db_migration-$PROJECT_ID --tail 5 2>&1")
    
    if echo "$MIGRATION_LOGS" | grep -q "No migrations to apply"; then
        echo "✅ Migration completed successfully"
        
        # Stop and remove migration container
        echo "2️⃣ Stopping migration container..."
        ssh root@$SERVER_IP "docker stop oncall_db_migration-$PROJECT_ID" > /dev/null 2>&1
        ssh root@$SERVER_IP "docker rm oncall_db_migration-$PROJECT_ID" > /dev/null 2>&1
        echo "✅ Migration container removed"
        
        # Check if engine and celery are stuck in Created state
        echo "3️⃣ Checking engine and celery containers..."
        
        ENGINE_STATUS=$(check_container "engine" | awk '{print $2}')
        CELERY_STATUS=$(check_container "celery" | awk '{print $2}')
        
        if [[ "$ENGINE_STATUS" == "Created" ]] || [[ "$CELERY_STATUS" == "Created" ]]; then
            echo "Found containers in 'Created' state"
            echo "4️⃣ Starting engine and celery containers..."
            
            ssh root@$SERVER_IP "docker start engine-$PROJECT_ID celery-$PROJECT_ID"
            echo "✅ Containers started"
        else
            echo "✅ Engine and celery containers are already running"
        fi
    else
        echo "⚠️  Migration may still be running or failed"
        echo "Migration logs:"
        echo "$MIGRATION_LOGS"
    fi
else
    echo "✅ No stuck migration container found"
fi

echo ""
echo "5️⃣ Final status check:"
echo "====================="
ssh root@$SERVER_IP "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E '(NAMES|engine|celery|grafana|redis)' | grep -E '(NAMES|$PROJECT_ID)'"

echo ""
echo "6️⃣ Testing service availability:"
GRAFANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:3000/api/health)
ONCALL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:8081/health/)

echo "Grafana: $GRAFANA_STATUS $([ "$GRAFANA_STATUS" == "200" ] && echo "✅" || echo "❌")"
echo "OnCall:  $ONCALL_STATUS $([ "$ONCALL_STATUS" == "200" ] && echo "✅" || echo "❌")"

echo ""
echo "🎉 Fix complete!"
echo ""
echo "If services are not responding:"
echo "1. Wait 30-60 seconds for them to fully start"
echo "2. Check Coolify dashboard for any errors"
echo "3. Run './post-deploy-setup.sh' to reconfigure OnCall plugin" 