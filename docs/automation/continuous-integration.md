# Continuous Integration

The project uses a GitHub Actions workflow defined in
[`.github/workflows/flutter_ci.yml`](../../.github/workflows/flutter_ci.yml).
It runs analysis and tests on every push. Release builds are generated for tags
matching `MVPv*`.
