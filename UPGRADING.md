# Upgrading

## v1.0.0

Instead of using `Alembic.FromJsonTest.assert_idempotent` use `Alembic.FromJsonCase.assert_idempotent`.  `Alembic.FromJsonCase` is defined in `test/support/from_json_case.ex`, so there is no need to explicitly include it when running a single file with `mix test <file>`.
