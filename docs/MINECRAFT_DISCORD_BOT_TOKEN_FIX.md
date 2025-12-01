# Minecraft Discord Bot Token Configuration Issue

**Date**: December 1, 2025  
**Issue**: Discord bot token not being injected into DiscordSRV config.yml

---

## Problem Analysis

### Root Cause

The DiscordSRV config template in the mc-server repository uses bash parameter expansion syntax that `envsubst` doesn't support:

```yaml
BotToken: "${DISCORD_BOT_TOKEN:?Discord bot token required}"
```

**Issue**: The `:?` syntax is bash-specific for "error if unset", but `envsubst` only supports simple variable substitution like `${VAR}` or `$VAR`.

### What Happens

1. Container starts with `DISCORD_BOT_TOKEN` environment variable set correctly
2. Entrypoint script processes templates using `envsubst`
3. `envsubst` doesn't recognize `${DISCORD_BOT_TOKEN:?...}` syntax
4. Result: Template is processed but the substitution doesn't happen
5. Final config has `BotToken: ""` (empty string)

### Evidence

```bash
# Environment variable IS set in container:
$ docker exec minecraft-server printenv | grep DISCORD_BOT_TOKEN
DISCORD_BOT_TOKEN=MTQ0NDg2Nzc2NjkyOTg1NDU5Nw...

# But processed config is empty:
$ docker exec minecraft-server cat /tmp/minecraft-configs/plugins/DiscordSRV/config.yml | grep BotToken
BotToken: ""

# And final config is placeholder:
$ docker exec minecraft-server cat /data/plugins/DiscordSRV/config.yml | grep BotToken
BotToken: "BOTTOKEN"
```

---

## Solution

### Option 1: Fix Template in mc-server Repository (Recommended)

Update `templates/plugins/DiscordSRV/config.yml.template` in the mc-server repository:

**File**: `templates/plugins/DiscordSRV/config.yml.template`

```diff
- BotToken: "${DISCORD_BOT_TOKEN:?Discord bot token required}"
+ BotToken: "${DISCORD_BOT_TOKEN}"
```

**Why**: Simple `${VAR}` syntax works with both `envsubst` and the perl fallback.

**Note**: You lose the error-on-unset behavior, but the plugin itself will error gracefully if the token is missing.

### Option 2: Improve entrypoint.sh to Handle Bash Syntax

Update the `scripts/entrypoint.sh` in mc-server repository to use bash for substitution:

```bash
# Replace this function in entrypoint.sh:
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    echo "Processing: $(basename "$template_file") -> $output_file"
    
    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"
    
    # Use bash to process template with full parameter expansion support
    ( source /dev/stdin ) < "$template_file" | cat > "$output_file" 2>/dev/null || \
    # Fallback to envsubst
    envsubst < "$template_file" > "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Generated successfully"
    else
        echo "  ✗ Failed to generate"
        return 1
    fi
}
```

**Why**: Uses bash's built-in parameter expansion which supports `:?` syntax.

### Option 3: Manual Fix for Existing Deployment

For immediate fix without rebuilding the container:

```bash
# SSH to host
ssh -J root@192.168.2.10 root@192.168.20.100

# Manually update the config
docker exec minecraft-server bash -c "sed -i 's/BotToken: .*/BotToken: \"$DISCORD_BOT_TOKEN\"/' /data/plugins/DiscordSRV/config.yml"

# Restart to apply
docker restart minecraft-server
```

---

## Implementation Steps

### Step 1: Fix mc-server Repository

1. Clone and update the repository:
```bash
cd /tmp
git clone https://github.com/LuckyPrayer/mc-server.git
cd mc-server

# Update the template
sed -i 's/${DISCORD_BOT_TOKEN:?Discord bot token required}/${DISCORD_BOT_TOKEN}/g' templates/plugins/DiscordSRV/config.yml.template

# Commit and push
git add templates/plugins/DiscordSRV/config.yml.template
git commit -m "Fix: Use envsubst-compatible syntax for DISCORD_BOT_TOKEN"
git push
```

2. Rebuild and push container images:
```bash
# Build development image
./build.sh dev

# Push to Harbor
./push-to-harbor.sh dev
```

### Step 2: Deploy Updated Image

1. Update Ansible inventory to pull latest image (or it will auto-pull if using `:dev-latest` tag)

2. Deploy:
```bash
cd /home/luckyprayer/Homelab
ansible-playbook -i inventories/dev/hosts.yml playbooks/deploy-docker-hosts.yml --limit orion-dev
```

### Step 3: Verify

```bash
# SSH to host
ssh -J root@192.168.2.10 root@192.168.20.100

# Check environment variable
docker exec minecraft-server printenv | grep DISCORD_BOT_TOKEN

# Check processed config
docker exec minecraft-server cat /data/plugins/DiscordSRV/config.yml | grep BotToken

# Check for Discord connection in logs
docker logs minecraft-server 2>&1 | grep -i discord | tail -20
```

---

## Quick Fix (Immediate)

For immediate resolution without rebuilding:

```bash
# Connect to host
ssh -J root@192.168.2.10 root@192.168.20.100

# Fix the config directly
docker exec minecraft-server bash -c '
  TOKEN=$DISCORD_BOT_TOKEN
  CONFIG=/data/plugins/DiscordSRV/config.yml
  sed -i "s/^BotToken: .*/BotToken: \"$TOKEN\"/" $CONFIG
  echo "Updated BotToken in config"
'

# Restart Minecraft server to reload config
docker restart minecraft-server

# Wait and verify
sleep 20
docker logs minecraft-server 2>&1 | grep -i discord | tail -10
```

---

## Testing

### Test Discord Connection

After fix is applied:

```bash
# Check logs for successful connection
docker logs minecraft-server 2>&1 | grep -i "discord.*connect\|discord.*ready\|discord.*online"

# Should see something like:
# [DiscordSRV] Connected to Discord successfully!
# [DiscordSRV] Bot is online!
```

### Test Discord Commands

In your Discord server:
1. Type `/discord link` - Should get a response from the bot
2. Check if chat messages sync between Minecraft and Discord

---

## Related Issues

### Similar Template Variables to Check

Other templates in mc-server that might have the same issue:

```bash
# Search for parameter expansion syntax
cd /tmp/mc-server
grep -r '\${[^}]*:' templates/

# Found:
templates/plugins/DiscordSRV/config.yml.template:BotToken: "${DISCORD_BOT_TOKEN:?Discord bot token required}"
```

Currently only affects the Discord bot token.

---

## Prevention

### Template Best Practices for mc-server

1. **Use simple variable syntax**: `${VAR}` instead of `${VAR:?error}` or `${VAR:-default}`
2. **Handle defaults in entrypoint**: Set default values before processing templates
3. **Document required variables**: In README or .env.example files
4. **Test templates**: Add template validation to build process

---

## Documentation References

- [MINECRAFT_DEPLOYMENT_REVIEW.md](MINECRAFT_DEPLOYMENT_REVIEW.md)
- [MINECRAFT_SECRETS_FIX_IMPLEMENTATION.md](MINECRAFT_SECRETS_FIX_IMPLEMENTATION.md)
- mc-server repository: https://github.com/LuckyPrayer/mc-server

---

**Status**: Issue identified, multiple solutions provided  
**Immediate Action**: Use quick fix to update config manually  
**Long-term Action**: Update template in mc-server repository
