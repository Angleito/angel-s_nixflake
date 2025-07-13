# SSH Key Protection

This repository has been configured with SSH key protection to prevent accidental commits of private keys and other sensitive SSH-related files.

## What's Protected

### .gitignore
The following SSH-related files are automatically ignored:
- Private keys: `id_rsa`, `id_ed25519`, `id_ecdsa`, `id_dsa`
- Public keys: `id_rsa.pub`, `id_ed25519.pub`, `id_ecdsa.pub`, `id_dsa.pub`
- SSH directories and config: `.ssh/`, `known_hosts`, `authorized_keys`, `ssh_config`
- Various key formats: `*.ssh`, `*.ppk`, `*.openssh`, `*.pem`, `*.key`, `*.crt`

### Pre-commit Hook
A pre-commit hook provides additional protection by:
- **Blocking** commits containing SSH private key content
- **Blocking** commits with SSH key file patterns
- **Warning** about SSH public keys (with option to proceed)

## Setup on New Machine

After cloning this repository on a new Mac, run:

```bash
./setup-hooks.sh
```

This will install the pre-commit hook that provides runtime protection against SSH key commits.

## Manual Verification

You can verify the protection is working by:

1. Checking that SSH key patterns are in `.gitignore`:
   ```bash
   grep -A 20 "SSH keys" .gitignore
   ```

2. Verifying the pre-commit hook is installed:
   ```bash
   ls -la .git/hooks/pre-commit
   ```

## Emergency Bypass

If you need to bypass the hook in an emergency (not recommended), use:
```bash
git commit --no-verify
```

## What to Do If SSH Keys Were Committed

If SSH keys were accidentally committed in the past:

1. **Immediately rotate the compromised keys**
2. Remove them from git history:
   ```bash
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch path/to/key' --prune-empty --tag-name-filter cat -- --all
   ```
3. Force push to update remote repository:
   ```bash
   git push origin --force --all
   ```
4. Contact team members to re-clone the repository

## Best Practices

- Never store SSH keys in version control
- Use SSH agent or key management tools
- Keep private keys in `~/.ssh/` directory only
- Use different keys for different services
- Regularly rotate SSH keys
