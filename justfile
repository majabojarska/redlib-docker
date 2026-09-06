default:
    @just --list

# Lint the Dockerfile with hadolint.
lint-docker:
    hadolint Dockerfile
