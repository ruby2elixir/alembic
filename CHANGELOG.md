# Changelog

## v1.0.0
 
### Enhancements
* [#1](https://github.com/C-S-D/alembic/pull/1) - [KronicDeth](https://github.com/KronicDeth)
  * CircleCI build setup
  * JUnit formatter for CircleCI's test output parsing
* [#2](https://github.com/C-S-D/alembic/pull/2) - [KronicDeth](https://github.com/KronicDeth)
  * `mix test --cover` with CoverEx
  * Archive coverage reports on CircleCI
* [#3](https://github.com/C-S-D/alembic/pull/3) - [KronicDeth](https://github.com/KronicDeth)
  * Use `ex_doc` and `earmark` to generate documentation with `mix docs`
  * Use `mix inch (--pedantic)` to see coverage for documentation
* [#4](https://github.com/C-S-D/alembic/pull/4) - [KronicDeth](https://github.com/KronicDeth)
  * Add repository to [hexfaktor](http://hexfaktor.org/), so that outdated hex dependencies are automatically notified through CI.
  * Add [hexfaktor](http://hexfaktor.org/) badge to [README.md](README.md)
* [#5](https://github.com/C-S-D/alembic/pull/5) - [KronicDeth](https://github.com/KronicDeth)
  * Configure `mix credo` to run against `lib` and `test` to maintain consistency with Ruby projects that use `rubocop` on `lib` and `spec`.
  * Run `mix credo --strict` on CircleCI to check style and consistency in CI
* [#6](https://github.com/C-S-D/alembic/pull/6) - [KronicDeth](https://github.com/KronicDeth)
  * Use [`dialyze`](https://github.com/fishcakez/dialyze) for dialyzer access with `mix dialyze`
* [#7](https://github.com/C-S-D/alembic/pull/7) - Validation and conversion of JSON API errors Documents - [KronicDeth](https://github.com/KronicDeth)
  * JSON API errors documents can be validated and converted to `%Alembic.Document{}` using `Alembic.Document.from_json/2`.  Invalid documents return `{:error, %Alembic.Document{}}`.  The `%Alembic.Document{}` can be sent back to the sender, which can be validated on the other end using `from_json/2`.  Valid documents return `{:ok, %Alembic.Document{}}`.
* [#8](https://github.com/C-S-D/alembic/pull/8) - JSON API (non-errors) Documents - [KronicDeth](https://github.com/KronicDeth)
  * `Alembic.ResourceIdentifier`
  * `Alembic.ResourceLinkage`
  * `Alembic.Relationship`
  * `Alembic.Relationships`
  * `Alembic.Resource`
  * `Alembic.Document` can parse `from_json`, represent, and encode with `Poison.encode` all document format, including `data` and `meta`, in addition to the prior support for `errors`
  * `assert_idempotent` is defined in a module, `Alembic.FromJsonCase` under `test/support`, so it's no longer necessary to run `mix test <file> test/interpreter_server/api/from_json_test.exs` to get access to `assert_idempotent` in `<file>`.  

### Bug Fixes

### Incompatible Changes
* [#8](https://github.com/C-S-D/alembic/pull/8) - JSON API (non-errors) Documents - [KronicDeth](https://github.com/KronicDeth)
  * `Alembic.FromJsonTest.assert_idempotent` has moved to `Alembic.FromJsonCase`.

