# Grafana OnCall Test Environment

Test deployment of Grafana OnCall on Coolify.

## Environment Setup

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your actual values:

   - `SERVER_IP` - Your server IP address
   - `COOLIFY_PROJECT_ID` - Your Coolify project ID
   - `BASE_URL` - Full OnCall URL (e.g., http://your-server-ip:8081)
   - `GRAFANA_USER` - Your Grafana username
   - `GRAFANA_PASSWORD` - Your Grafana admin password
   - `ONCALL_USERNAME` - Your OnCall username (for mobile app QR generation)
   - `SECRET_KEY` - A secure secret key (32+ characters)
   - Update other values as needed

3. The `.env` file is gitignored and should never be committed to version control.

# Grafana OnCall OSS - Coolify Deployment

This repository contains the configuration to run Grafana OnCall OSS on Hetzner using Coolify, with Grafana Cloud connectivity for mobile app support.

## 🚀 Quick Access

- **Grafana:** http://<your-server-ip>:3000
  - Username: `<your-grafana-username>`
  - Password: `<your-password-here>`
- **OnCall API:** http://<your-server-ip>:8081
- **Coolify Dashboard:** http://<your-server-ip>:8000

## ⚠️ Maintenance Mode Notice

As of 2025-03-11, Grafana OnCall OSS has entered maintenance mode and will be archived on 2026-03-24. Consider [Grafana Cloud IRM](https://grafana.com/docs/oncall/latest/set-up/migration-from-other-tools/) for a fully supported alternative.

## 📱 Mobile App Setup

### Quick Setup

```bash
# Generate QR code for mobile app
./get-mobile-app-qr.sh

# Open the generated QR code in your browser
open mobile-app-qr-deeplink.html  # macOS
xdg-open mobile-app-qr-deeplink.html  # Linux
```

Scan the QR code with your phone - it will automatically open the Grafana mobile app and connect to your OnCall instance.

### Deep Link Format

The mobile app uses deep links in the format:

```
grafana://mobile/login/link-login?oncall_api_url=http://<your-server-ip>:8081&token=YOUR_TOKEN
```

Get the current token by running `./get-mobile-app-qr.sh`.

## 🔧 Deployment Management

### Initial Deployment

1. Deploy using the Coolify dashboard
2. After deployment completes, run:
   ```bash
   ./fix-coolify-redeploy.sh  # Fix migration container issue
   ./post-deploy-setup.sh      # Configure OnCall plugin
   ```

### Redeploying/Restarting

After any redeploy in Coolify:

```bash
# Fix the stuck migration container
./fix-coolify-redeploy.sh

# Reconfigure OnCall plugin if needed
./post-deploy-setup.sh
```

### Service Management

```bash
# SSH into server
ssh root@<your-server-ip>

# Check service status
docker ps | grep <your-coolify-project-id>

# View logs
docker logs engine-<your-coolify-project-id> --tail 50
docker logs grafana-<your-coolify-project-id> --tail 50
docker logs celery-<your-coolify-project-id> --tail 50

# Restart services
docker restart engine-<your-coolify-project-id>
docker restart grafana-<your-coolify-project-id>
```

## 🐛 Known Issues & Solutions

### Migration Container Stuck After Redeploy

**Issue:** Migration container keeps restarting, preventing other services from starting.

**Solution:** Run `./fix-coolify-redeploy.sh`

**Root Cause:** The migration container has `restart: unless-stopped` but should exit after completion. The script removes this container after migrations complete.

### OnCall Plugin Disconnected

**Issue:** Grafana shows "Plugin is not connected to OnCall engine"

**Solution:** Run `./post-deploy-setup.sh`

### Mobile App Connection Issues

**Issue:** Can't find QR code in Grafana UI (IRM tab missing)

**Solution:** Use `./get-mobile-app-qr.sh` to generate QR code directly

**Root Cause:** Grafana 12 requires `pluginExtensions` feature toggle. To fix permanently, add to Grafana environment in Coolify:

```
GF_FEATURE_TOGGLES_ENABLE=externalServiceAccounts,pluginExtensions
```

### Mobile App Permission Errors

**Issue:** "You do not have permission to perform this action"

**Possible Causes:**

- Token has expired (tokens are valid for 5 minutes)
- Mobile app requires HTTPS connection
- Run `./get-mobile-app-qr.sh` for a fresh token

## 📁 Repository Structure

```
├── docker-compose.coolify.yml  # Coolify deployment configuration
├── coolify.env                 # Environment variables
├── fix-coolify-redeploy.sh     # Fix migration container after redeploy
├── post-deploy-setup.sh        # Configure OnCall plugin in Grafana
├── get-mobile-app-qr.sh        # Generate mobile app QR code
├── mobile-app-qr-deeplink.template.html # QR code template
├── coolify-https-setup.md      # HTTPS configuration guide
└── README.md                   # This file
```

## 🔐 Configuration Details

### Environment Variables

Key variables in `coolify.env`:

- `SECRET_KEY` - Django secret key (keep secure!)
- `GRAFANA_CLOUD_ONCALL_API_URL` - Cloud OnCall endpoint (EU region)
- `GRAFANA_CLOUD_ONCALL_TOKEN` - API token for mobile app support

### Cloud Connection

- **Cloud Instance:** <your-grafana-cloud-instance> (EU region)
- **OnCall API:** https://oncall-prod-eu-west-0.grafana.net/oncall
- **Purpose:** Enables mobile app push notifications

## 🚨 Troubleshooting

### Health Checks

```bash
# Grafana health
curl http://<your-server-ip>:3000/api/health

# OnCall health
curl http://<your-server-ip>:8081/health/
```

### Emergency Recovery

1. Check Coolify is running:

   ```bash
   ssh root@<your-server-ip>
   docker ps | grep coolify
   ```

2. Redeploy from Coolify dashboard

3. Run recovery scripts:
   ```bash
   ./fix-coolify-redeploy.sh
   ./post-deploy-setup.sh
   ```

## 🔒 Security Considerations

- Currently running on HTTP - see `coolify-https-setup.md` for HTTPS setup
- Firewall is disabled on the server
- All services are publicly accessible on their respective ports

## 📚 Resources

- [OnCall Documentation](https://grafana.com/docs/oncall/latest/)
- [OnCall GitHub](https://github.com/grafana/oncall)
- [Coolify Documentation](https://coolify.io/docs)
- [Mobile App Documentation](https://grafana.com/docs/oncall/latest/mobile-app/)

---

**Project ID:** <your-coolify-project-id>  
**Last Updated:** May 2025
