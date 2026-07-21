# Jobs

Architecture: [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md). Domain: [docs/DOMAIN.md](../../docs/DOMAIN.md). TDD: [docs/TESTING.md](../../docs/TESTING.md).

- Use Active Job with the installed Solid Queue adapter; do not add another queue system
- Keep jobs thin: load records safely and call tested model/domain APIs
- Design retries to be idempotent; handle deleted or stale records without corrupting state
- Document scheduling, cancellation, recipient, and duplicate-delivery behavior in the domain model specs
- Use `deliver_later`; do not perform synchronous external delivery in request paths
- No migrations, generators, queue commands, or new infrastructure without explicit approval
