---
description: |
  Shared reusable component for setting up Elixir/Phoenix development.
  Provides PostgreSQL database, and configures Elixir/Erlang.
  Import this component in your agentic workflows to get a fully configured Elixir environment.

services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: stream_closed_captioner_phoenix_test
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
    ports:
      - 5432:5432

steps:
  - uses: erlef/setup-beam@v1
    with:
      otp-version: "26"
      elixir-version: "1.16"

tools:
  bash: true

network:
  allowed:
    - defaults
    - elixir
    - github
---

# Elixir Setup Component

This shared component configures a complete Elixir/Phoenix development and testing environment.

## What This Provides

- **PostgreSQL 15**: Running database service with health checks
- **Elixir 1.16**: Configured with Erlang/OTP 26
- **Network Access**: Allowed access to Hex.pm and GitHub for package management

## Usage in Workflows

Import this component in your workflow's frontmatter:

```yaml
source: .github/workflows/shared/elixir-setup.md
```

Then in your workflow, you can run Elixir commands:

```bash
mix test
mix format --check-formatted
mix credo
mix coveralls
```

## Environment Setup Steps

The component automatically handles:

1. **Setting up Erlang/OTP 26 and Elixir 1.16**

## Database Configuration

PostgreSQL is available at:
- Host: `localhost`
- Port: `5432`
- User: `postgres`
- Password: `postgres`
- Database: `stream_closed_captioner_phoenix_test`

Connection string: `postgres://postgres:postgres@localhost:5432/stream_closed_captioner_phoenix_test`

## Setup Instructions

When you use this component, you should:

1. Install dependencies with: `mix deps.get`
2. Compile the project with: `mix compile`
3. Wait for PostgreSQL to be fully healthy before running database commands

## Testing New Features or Changes

**IMPORTANT**: When developing new tests or features, you MUST run tests to verify your changes:

1. **After writing new tests**: Run `mix test` to ensure the new tests pass and don't break existing tests
2. **After implementing features**: Run the relevant test suite to verify functionality
3. **Before finalizing changes**: Run the full test suite with `mix test --trace` to catch any issues
4. **Check code quality**: Run `mix format` to format code and `mix credo` for static analysis

### Testing Workflow

```bash
# 1. Install/update dependencies
mix deps.get

# 2. Compile the project
mix compile

# 3. Run tests
mix test

# 4. Check formatting
mix format

# 5. Run static analysis
mix credo
```

If tests fail, review the error output, fix the issues, and re-run the tests. Do not proceed without passing tests.

## Common Commands

Once the environment is set up, you can run:

- **Run tests**: `mix test`
- **Run specific test**: `mix test test/path/to/test.exs`
- **Check formatting**: `mix format --check-formatted`
- **Run linter**: `mix credo`
- **Generate coverage**: `mix coveralls`
- **Run interactive shell**: `iex -S mix`
- **Setup Database**: `mix ecto.setup`
- **Database migrations**: `mix ecto.migrate`
- **Reset database**: `mix ecto.reset`


## Notes

- The PostgreSQL service uses health checks to ensure it's ready before tests run
- The database is automatically destroyed and recreated for each workflow run
- Use `MIX_ENV=test` for test environment (default for this component)
