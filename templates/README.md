# Templates Library

Reusable script templates and patterns for AI-assisted development.

## Available Templates

| Template | Description | Use Case |
|----------|-------------|----------|
| [[tools-installer-template.md]] | Parallel, fault-tolerant CLI tool installer | Installing multiple tools with verification — production implementation lives at `../scripts/tools/parallel-tools-installer.sh` (tested 18/18 on Ubuntu 24.04) |

## Template Guidelines

### When Creating New Templates
1. **Single responsibility** - One template per pattern
2. **Parameterized** - Use environment variables for configuration
3. **Idempotent** - Safe to run multiple times
4. **Verifiable** - Include verification logic
5. **Documented** - Clear usage examples

### Template Structure
```
templates/
├── <template-name>.md      # Documentation + example script
├── <template-name>.sh      # Executable reference implementation (optional)
└── lib/                    # Shared helpers (optional)
```

## Using Templates

### As Reference
Read the `.md` file for the pattern, then adapt to your needs.

### As Executable
If a `.sh` version exists:
```bash
# Copy and customize
cp templates/tools-installer-template.sh my-installer.sh
chmod +x my-installer.sh
# Edit TOOLS and BINARIES arrays
./my-installer.sh
```

## Contributing Templates

1. Create `<name>.md` with:
   - Purpose and use cases
   - Features list
   - Configuration options
   - Complete example script
   - Usage instructions
2. Optionally add `<name>.sh` as runnable reference
3. Update this README with new entry

## Related Documentation

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent cross-references
- [[scripts/tools/README.md]] - Tools module using installer pattern
- [[scripts/tools/cloudflare/README.md]] - Cloudflare tools
- [[scripts/tools/tailscale/README.md]] - Tailscale tools