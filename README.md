# Alembic

[![CircleCI](https://circleci.com/gh/C-S-D/alembic.svg?style=svg)](https://circleci.com/gh/C-S-D/alembic)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/C-S-D/alembic.svg)](https://beta.hexfaktor.org/github/C-S-D/alembic)
[![Inline docs](http://inch-ci.org/github/C-S-D/alembic.svg)](http://inch-ci.org/github/C-S-D/alembic)

A JSONAPI 1.0 library fully-tested against all jsonapi.org examples.  The library generates JSONAPI errors documents whenever it encounters a malformed JSONAPI document, so that servers don't need to worry about JSONAPI format errors.  Poison.Encoder implementations ensure the structs can be turned back into JSON strings: struct->encoding->decoding->conversion to struct is tested to ensure idempotency and that the library can parse its own JSONAPI errors documents.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add alembic to your list of dependencies in `mix.exs`:

        def deps do
          [{:alembic, "~> 1.0.0"}]
        end

  2. Ensure alembic is started before your application:

        def application do
          [applications: [:alembic]]
        end

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
