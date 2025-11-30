# Fedora/RHEL/CentOS SELinux Configuration

## Overview

This project is fully compatible with **Fedora**, **RHEL**, and **CentOS** systems that have **SELinux in Enforcing mode**. The docker-compose files have been configured with the appropriate SELinux labels.

## SELinux Context Labels

### What Are :Z and :z Flags?

Docker volume mounts on SELinux systems require special labels to grant container access:

- **`:Z`** (uppercase) - **Private unshared label**
  - Used for read-write volumes that only ONE container should access
  - Docker applies a unique SELinux label (e.g., `svirt_sandbox_file_t`)
  - **Used for**: `data-dev`, `data-prod`, `logs-dev`, `logs-prod`
  
- **`:z`** (lowercase) - **Shared label**
  - Used for read-only volumes that MULTIPLE containers might access
  - Docker applies a shared SELinux label
  - **Used for**: `datapacks`, `plugins`, `resourcepacks`, `config`

## docker-compose Configuration

Both `docker-compose.dev.yml` and `docker-compose.prod.yml` include SELinux labels:

```yaml
volumes:
  # Read-write data directory - private label
  - ./data-dev:/data:Z
  
  # Read-only shared directories
  - ./datapacks:/datapacks:ro,z
  - ./plugins:/plugins:ro,z
  - ./resourcepacks:/resourcepacks:ro,z
  - ./config:/config:ro,z
  
  # Logs directory - private label
  - ./logs-dev:/data/logs:Z
```

## Troubleshooting

### Permission Denied Errors

If you see errors like:
```
chown: cannot read directory '/data': Permission denied
/data/eula.txt: Permission denied
```

**Solution**: Ensure volume mounts include `:Z` or `:z` flags as shown above.

### Check SELinux Status

```bash
# Check if SELinux is enabled
getenforce
# Should return: Enforcing, Permissive, or Disabled

# Check SELinux context of mounted directories
ls -Z ./data-dev
```

### Verify Volume Labels

After starting the container, verify SELinux labels are applied:

```bash
# Check the data directory label
ls -dZ ./data-dev
# Should show something like: system_u:object_r:container_file_t:s0:c123,c456
```

### Alternative Solutions (Not Recommended)

If you need to run without SELinux labels (testing only):

1. **Temporarily disable SELinux** (requires reboot):
   ```bash
   sudo setenforce 0  # Permissive mode
   # To re-enable: sudo setenforce 1
   ```

2. **Use --privileged mode** (security risk):
   ```yaml
   services:
     minecraft-server:
       privileged: true  # Not recommended for production
   ```

3. **Manually set volume ownership** (before first start):
   ```bash
   sudo chown -R 1000:1000 ./data-dev
   ```

## Best Practices

1. ✅ **Always use `:Z` for private read-write volumes**
2. ✅ **Always use `:z` for shared read-only volumes**
3. ✅ **Keep SELinux in Enforcing mode** for security
4. ✅ **Test volume permissions after first start**
5. ❌ **Never run containers with `--privileged` in production**
6. ❌ **Never disable SELinux in production environments**

## Resources

- [Docker and SELinux Documentation](https://docs.docker.com/storage/bind-mounts/#configure-the-selinux-label)
- [Red Hat: Using Docker with SELinux](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/managing_containers/using_volumes_with_docker_formatted_containers#mounting_a_host_directory_on_selinux_enabled_systems)
- [Fedora SELinux Guide](https://docs.fedoraproject.org/en-US/quick-docs/getting-started-with-selinux/)

## Support

This configuration has been tested on:
- ✅ Fedora 39+ (SELinux Enforcing)
- ✅ RHEL 8/9 (SELinux Enforcing)
- ✅ CentOS Stream 8/9 (SELinux Enforcing)

The same configuration also works on systems without SELinux (Ubuntu, Debian, etc.) - the `:Z` and `:z` flags are simply ignored.
