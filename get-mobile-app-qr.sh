#!/bin/bash

# Script to get mobile app QR code data from OnCall backend

# Source environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    echo "   Please create a .env file with ONCALL_USERNAME variable"
    exit 1
fi

# Check if ONCALL_USERNAME is set
if [ -z "$ONCALL_USERNAME" ]; then
    echo "❌ Error: ONCALL_USERNAME not set in .env file"
    exit 1
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

echo "📱 Fetching OnCall Mobile App QR Code Data"
echo "=========================================="
echo ""
echo "👤 User: $ONCALL_USERNAME"
echo ""

# Get the QR code data from the OnCall backend
QR_DATA=$(ssh root@${SERVER_IP} "docker exec engine-${PROJECT_ID} python manage.py shell -c \"from apps.user_management.models import User; from apps.mobile_app.backend import MobileAppBackend; u = User.objects.filter(username='$ONCALL_USERNAME').first(); backend = MobileAppBackend(); code = backend.generate_user_verification_code(u); print(code)\"" 2>/dev/null | tail -1)

if [ -z "$QR_DATA" ]; then
    echo "❌ Failed to fetch QR code data"
    exit 1
fi

echo "✅ QR Code Data:"
echo "$QR_DATA" | jq .

# Extract token and URL
TOKEN=$(echo "$QR_DATA" | jq -r '.token')
URL=$(echo "$QR_DATA" | jq -r '.oncall_api_url')

# Override the URL with the correct BASE_URL from .env
echo ""
echo "⚠️  Backend returned URL: $URL"
echo "✅ Using correct URL: $BASE_URL"
URL="$BASE_URL"

echo ""
echo "�� Connection Details:"
echo "   Token: $TOKEN"
echo "   OnCall URL: $URL"
echo ""
echo "🔗 To connect your mobile app:"
echo "   1. Open mobile-app-qr-deeplink.html in your browser"
echo "   2. Scan the QR code with your phone"
echo "   3. The Grafana mobile app will open automatically"
echo ""
echo "⚠️  Note: Make sure your mobile device can reach $URL"

# Create/update the deep link HTML file from template
if [ -f "mobile-app-qr-deeplink.template.html" ]; then
    echo ""
    echo "📝 Creating mobile-app-qr-deeplink.html from template with latest token..."
    cp mobile-app-qr-deeplink.template.html mobile-app-qr-deeplink.html
    sed -i.bak "s/var token = \".*\"/var token = \"$TOKEN\"/" mobile-app-qr-deeplink.html
    sed -i.bak "s|var oncallApiUrl = \".*\"|var oncallApiUrl = \"$URL\"|" mobile-app-qr-deeplink.html
    rm mobile-app-qr-deeplink.html.bak
    echo "✅ Deep link QR code created!"
else
    echo ""
    echo "⚠️  Warning: mobile-app-qr-deeplink.template.html not found"
    echo "   Cannot generate QR code HTML file"
fi

echo ""
echo "🔗 Deep link format:"
echo "grafana://mobile/login/link-login?oncall_api_url=$URL&token=$TOKEN" 