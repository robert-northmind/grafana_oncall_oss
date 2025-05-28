#!/bin/bash

# Post-deployment setup script for Grafana OnCall
# This script configures the OnCall plugin in Grafana after deployment

set -e

# Source environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Configuration
PROJECT_ID="${COOLIFY_PROJECT_ID}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"

# Check if we're running locally or need to SSH to server
if [ -f /.dockerenv ]; then
    # We're inside a container
    SERVER_IP="${COOLIFY_SERVER_IP:-${SERVER_IP}}"
    SSH_PREFIX="ssh root@$SERVER_IP"
else
    # We're running locally
    SERVER_IP="${SERVER_IP}"
    if [ -z "$SERVER_IP" ]; then
        echo "❌ Error: SERVER_IP not set in .env file"
        exit 1
    fi
    if [ -z "$PROJECT_ID" ]; then
        echo "❌ Error: COOLIFY_PROJECT_ID not set in .env file"
        exit 1
    fi
    if [[ $(hostname -I 2>/dev/null | grep -o "$SERVER_IP" || echo "") == "" ]]; then
        SSH_PREFIX="ssh root@$SERVER_IP"
    else
        SSH_PREFIX=""
    fi
fi

GRAFANA_URL="http://${SERVER_IP}:3000"
ONCALL_URL="http://${SERVER_IP}:8081"

echo "🔧 Configuring Grafana OnCall Plugin"
echo "===================================="

echo "Waiting for services to be ready..."
echo "Checking Grafana..."

# Wait for Grafana to be ready
until curl -s -f -o /dev/null "$GRAFANA_URL/api/health"; do
    echo -n "."
    sleep 5
done
echo " ✅ Grafana is ready!"

echo "Checking OnCall Engine..."
# Wait for OnCall to be ready
until curl -s -f -o /dev/null "$ONCALL_URL/health/"; do
    echo -n "."
    sleep 5
done
echo " ✅ OnCall Engine is ready!"

echo ""
echo "📌 Enabling OnCall plugin..."

# Enable the OnCall plugin
RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/plugins/grafana-oncall-app/settings" \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
  -d '{
    "enabled": true,
    "jsonData": {
      "stackId": 5,
      "orgId": 100,
      "onCallApiUrl": "'$ONCALL_URL'",
      "grafanaUrl": "'$GRAFANA_URL'"
    }
  }')

if echo "$RESPONSE" | grep -q "Plugin settings updated"; then
    echo "✅ OnCall plugin enabled successfully!"
else
    echo "⚠️  Plugin enable response: $RESPONSE"
fi

echo ""
echo "🔄 Restarting Grafana to ensure plugin loads..."
if [ -n "$GRAFANA_CONTAINER" ]; then
    $SSH_PREFIX docker restart $GRAFANA_CONTAINER >/dev/null 2>&1
    echo "✅ Grafana restarted"
    echo "⏳ Waiting for Grafana to come back up..."
    sleep 10
    until curl -s -f -o /dev/null "$GRAFANA_URL/api/health"; do
        echo -n "."
        sleep 2
    done
    echo " ✅ Grafana is ready!"
else
    echo "⚠️  Could not find Grafana container to restart"
fi

echo ""
echo "📦 Installing plugin resources..."

# Install plugin resources
RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/plugins/grafana-oncall-app/resources/plugin/install" \
  -u "$GRAFANA_USER:$GRAFANA_PASSWORD")

if echo "$RESPONSE" | grep -q "error"; then
    echo "⚠️  Resource install response: $RESPONSE"
else
    echo "✅ Plugin resources installed!"
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Access your services:"
echo "- Grafana: $GRAFANA_URL"
echo "  Username: $GRAFANA_USER"
echo "  Password: [as configured]"
echo ""
echo "- OnCall Plugin: Available in Grafana sidebar"
echo ""
echo "📱 For mobile app setup:"
echo "1. Log into Grafana"
echo "2. Navigate to OnCall → Cloud"
echo "3. Follow instructions to connect to Grafana Cloud"
echo "4. Scan QR code with OnCall mobile app"
echo ""
echo "⚠️  Note: Mobile app requires connection to Grafana Cloud for push notifications" 