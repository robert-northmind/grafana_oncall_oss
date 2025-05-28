# Setting Up HTTPS in Coolify

## Prerequisites

- A domain name (e.g., oncall.yourdomain.com)
- DNS A records pointing to <your-server-ip>

## Step 1: Configure DNS

Create A records for:

```
oncall.yourdomain.com     → <your-server-ip>
grafana.yourdomain.com    → <your-server-ip>
```

## Step 2: Update Environment Variables

Update `coolify.env`:

```bash
# Update these with your actual domains
ONCALL_DOMAIN=oncall.yourdomain.com
GRAFANA_DOMAIN=grafana.yourdomain.com
DOMAIN=https://oncall.yourdomain.com

# Keep the rest as is
SECRET_KEY=<your-secret-key-must-be-more-than-32-characters>
GRAFANA_USER=admin
GRAFANA_PASSWORD=<your-grafana-password>
GRAFANA_CLOUD_ONCALL_API_URL=https://oncall-prod-eu-west-0.grafana.net/oncall
```

## Step 3: Update Coolify Settings

1. **In Coolify Dashboard:**

   - Go to your OnCall project
   - Click on each service (engine, grafana)
   - Update the "Domains" section:
     - For engine: `https://oncall.yourdomain.com`
     - For grafana: `https://grafana.yourdomain.com`
   - Enable "Force HTTPS"
   - Enable "Generate SSL Certificate"

2. **Update Environment Variables in Coolify:**
   - Copy the updated values from `coolify.env`
   - Paste into Coolify's environment variables section

## Step 4: Redeploy

1. Click "Redeploy" in Coolify
2. Wait for deployment to complete
3. Run the fix script:
   ```bash
   ./fix-coolify-redeploy.sh
   ```

## Step 5: Update OnCall Plugin Configuration

After HTTPS is working:

```bash
# Update the plugin to use HTTPS URLs
./post-deploy-setup.sh
```

## Free Domain Options

If you don't have a domain, you can use:

1. **DuckDNS** (free subdomain)

   - Visit https://www.duckdns.org
   - Create subdomains like: yourname.duckdns.org
   - Point them to <your-server-ip>

2. **Cloudflare** (free with domain)

   - Use Cloudflare's free tier
   - Get SSL and DDoS protection

3. **nip.io** (automatic wildcard DNS)
   - Use: 91-99-121-174.nip.io
   - Subdomains: oncall.91-99-121-174.nip.io

## Verification

Once deployed with HTTPS:

```bash
# Test HTTPS endpoints
curl -I https://oncall.yourdomain.com/health/
curl -I https://grafana.yourdomain.com/api/health

# Check certificate
openssl s_client -connect oncall.yourdomain.com:443 -servername oncall.yourdomain.com < /dev/null
```

## Important Notes

- Coolify automatically renews Let's Encrypt certificates
- HTTP will redirect to HTTPS automatically
- First certificate generation may take 1-2 minutes
- Let's Encrypt rate limits: 50 certificates per domain per week
