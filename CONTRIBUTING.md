# Contributing to Yield Aggregator

We welcome contributions to the Yield Aggregator smart contract! This document provides guidelines and instructions for contributing.

## Development Process

1. **Fork the Repository**
   - Create your own fork of the project
   - Set up your local development environment

2. **Create a Feature Branch**
   - Branch naming convention: `feature/description` or `fix/description`
   - Keep changes focused and atomic

3. **Development Guidelines**

   - Follow Clarity best practices
   - Maintain consistent code style
   - Add comments for complex logic
   - Update documentation as needed

4. **Testing Requirements**

   - Add tests for new features
   - Ensure all existing tests pass
   - Test edge cases thoroughly
   - Document test scenarios

5. **Code Review Process**

   - Submit detailed pull requests
   - Respond to review comments
   - Make requested changes promptly
   - Ensure CI checks pass

## Code Style Guidelines

### Clarity Conventions

```clarity
;; Use clear, descriptive names
(define-constant MAX-STRATEGIES u10)

;; Group related functions
;; Strategy management functions
(define-public (add-strategy ...) ...)
(define-public (update-strategy ...) ...)

;; Add meaningful comments
;; Calculate user's share of the pool based on deposit amount
(define-private (calculate-shares (amount uint)) ...)
```

### Documentation Standards

- Use clear, concise comments
- Document function parameters and return values
- Explain complex calculations
- Update README for significant changes

## Testing Guidelines

1. **Unit Tests**
   - Test individual functions
   - Cover edge cases
   - Verify error conditions

2. **Integration Tests**
   - Test interaction between components
   - Verify end-to-end workflows
   - Test with realistic data

3. **Security Tests**
   - Test access controls
   - Verify fund safety
   - Check error handling

## Submitting Changes

1. **Pull Request Process**
   - Create detailed PR description
   - Reference related issues
   - Include test results
   - Update documentation

2. **Review Process**
   - Address review comments
   - Make requested changes
   - Maintain PR discussion

3. **Merge Requirements**
   - All tests passing
   - Documentation updated
   - Code review approved
   - CI checks successful

## Getting Help

- Join our developer community
- Ask questions in issues
- Review existing documentation
- Contact maintainers