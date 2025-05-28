# OnCall Plugin Troubleshooting Guide

## Common Issue: OnCall Plugin Not Visible in Grafana

### Problem

After deployment, the OnCall plugin may not appear in Grafana's sidebar even though it's installed.

### Root Causes & Solutions

1. **Plugin Not Enabled**

   - The plugin may be installed but not enabled
   - Solution: Restart Grafana container to ensure plugin loads properly

2. **Container Name Mismatch**

   - Coolify generates unique container names with suffixes (e.g., `grafana-<your-coolify-project-id>`)
   - Container names change between deployments
   - Solution: Always check actual container names on the server

3. **Configuration Location**
   - Plugin configuration must be done on the Coolify server, not locally
   - All Docker commands must be run via SSH to the server

### Troubleshooting Steps

1. **Verify Plugin Installation**

   ```bash
   ssh root@<server-ip> "docker exec <grafana-container-name> grafana cli plugins ls"
   ```

2. **Check Container Names**

   ```bash
   ssh root@<server-ip> "docker ps --format 'table {{.Names}}\t{{.Image}}' | grep grafana"
   ```

3. **Restart Grafana Container**

   ```bash
   ssh root@<server-ip> "docker restart <grafana-container-name>"
   ```

4. **Verify Grafana Health**
   ```bash
   ssh root@<server-ip> "curl -s http://localhost:3000/api/health"
   ```

### Important Notes

- **Always SSH to the server** - Don't run Docker commands locally
- **Container names change** - Coolify appends unique suffixes to container names
- **Plugin loads on restart** - Sometimes a simple restart is all that's needed
- **Check environment variables** - Use `docker inspect` to verify configuration

### First-Time OnCall Setup

After the plugin is visible:

1. Navigate to OnCall in Grafana sidebar
2. Configure the OnCall API URL (use internal Docker network names)
3. The backend URL format: `http://engine-<coolify-suffix>:8080`

### Prevention

- Include container restart in deployment scripts
- Document the actual container naming pattern
- Add health checks for plugin availability
