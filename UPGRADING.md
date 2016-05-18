<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Upgrading](#upgrading)
  - [v1.0.0](#v100)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Upgrading

## v1.0.0

Instead of using `Alembic.FromJsonTest.assert_idempotent` use `Alembic.FromJsonCase.assert_idempotent`.  `Alembic.FromJsonCase` is defined in `test/support/from_json_case.ex`, so there is no need to explicitly include it when running a single file with `mix test <file>`.
