# Contributing to ArgoCD Deployer

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, versions, etc.)
   - Relevant logs or error messages

### Suggesting Enhancements

1. Open an issue describing:
   - The enhancement you'd like to see
   - Why it would be useful
   - Possible implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Guidelines

### Code Style

- Use clear, descriptive variable names
- Comment complex logic
- Follow existing code style and patterns
- Keep functions/tasks focused and single-purpose

### Ansible

- Use YAML syntax consistently
- Tag tasks appropriately
- Make playbooks idempotent
- Test on clean systems

### Documentation

- Update README.md for user-facing changes
- Update TROUBLESHOOTING.md for new issues/solutions
- Add comments for non-obvious code
- Keep examples up to date

### Testing

Before submitting a PR:
1. Test full deployment on clean system
2. Test individual components
3. Verify documentation accuracy
4. Check for security issues

## Project Structure

```
argo-deployer/
├── ansible/          # Ansible playbooks and roles
├── config/           # Configuration files
├── docs/             # Documentation
├── inventory/        # Ansible inventory
└── scripts/          # Shell scripts
```

## Questions?

Open an issue for questions or discussion.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
