defmodule Alembic.DocumentTest do
  @moduledoc """
  Run doctests for `Alembic.Document`
  """

  use ExUnit.Case, async: true

  alias Alembic.Document
  alias Alembic.Error
  alias Alembic.FromJsonCase
  alias Alembic.Relationship
  alias Alembic.Resource
  alias Alembic.ResourceIdentifier
  alias Alembic.Source

  # Constants

  @error_template %Error{
    source: %Source{
      pointer: ""
    }
  }

  # Tests

  doctest Document

  # See http://jsonapi.org/format/#document-compound-documents"

  test "complete example with multiple included relationships" do
    {:ok, decoded} = Poison.decode """
    {
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!"
        },
        "links": {
          "self": "http://example.com/articles/1"
        },
        "relationships": {
          "author": {
            "links": {
              "self": "http://example.com/articles/1/relationships/author",
              "related": "http://example.com/articles/1/author"
            },
            "data": {"type": "people", "id": "9"}
          },
          "comments": {
            "links": {
              "self": "http://example.com/articles/1/relationships/comments",
              "related": "http://example.com/articles/1/comments"
            },
            "data": [
              {"type": "comments", "id": "5"},
              {"type": "comments", "id": "12"}
            ]
          }
        }
      }],
      "included": [{
        "type": "people",
        "id": "9",
        "attributes": {
          "first-name": "Dan",
          "last-name": "Gebhardt",
          "twitter": "dgeb"
        },
        "links": {
          "self": "http://example.com/people/9"
        }
      }, {
        "type": "comments",
        "id": "5",
        "attributes": {
          "body": "First!"
        },
        "relationships": {
          "author": {
            "data": {"type": "people", "id": "2"}
          }
        },
        "links": {
          "self": "http://example.com/comments/5"
        }
      }, {
        "type": "comments",
        "id": "12",
        "attributes": {
          "body": "I like XML better"
        },
        "relationships": {
          "author": {
            "data": {"type": "people", "id": "9"}
          }
        },
        "links": {
          "self": "http://example.com/comments/12"
        }
      }]
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %Resource{
          attributes: %{
            "title" => "JSON API paints my bikeshed!"
          },
          id: "1",
          links: %{
            "self" => "http://example.com/articles/1"
          },
          relationships: %{
            "author" => %Relationship{
              data: %ResourceIdentifier{
                id: "9",
                type: "people"
              },
              links: %{
                "related" => "http://example.com/articles/1/author",
                "self" => "http://example.com/articles/1/relationships/author"
              }
            },
            "comments" => %Relationship{
              data: [
                %ResourceIdentifier{
                  id: "5",
                  type: "comments"
                },
                %ResourceIdentifier{
                  id: "12",
                  type: "comments"
                }
              ],
              links: %{
                "related" => "http://example.com/articles/1/comments",
                "self" => "http://example.com/articles/1/relationships/comments"
              }
            }
          },
          type: "articles"
        }
      ],
      included: [
        %Resource{
          attributes: %{
            "first-name" => "Dan",
            "last-name" => "Gebhardt",
            "twitter" => "dgeb"
          },
          id: "9",
          links: %{
            "self" => "http://example.com/people/9"
          },
          type: "people"
        },
        %Resource{
          attributes: %{
            "body" => "First!"
          },
          id: "5",
          links: %{
            "self" => "http://example.com/comments/5"
          },
          relationships: %{
            "author" => %Relationship{
              data: %ResourceIdentifier{
                id: "2",
                type: "people"
              }
            }
          },
          type: "comments"
        },
        %Resource{
          attributes: %{
            "body" => "I like XML better"
          },
          id: "12",
          links: %{
            "self" => "http://example.com/comments/12"
          },
          relationships: %{
            "author" => %Relationship{
              data: %ResourceIdentifier{
                id: "9",
                type: "people"
              }
            }
          },
          type: "comments"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#fetching-resources-responses-200

  test "fetching resources responses 200 collection of articles" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "http://example.com/articles"
      },
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!"
        }
      }, {
        "type": "articles",
        "id": "2",
        "attributes": {
          "title": "Rails is Omakase"
        }
      }]
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %Resource{
          attributes: %{
            "title" => "JSON API paints my bikeshed!"
          },
          id: "1",
          type: "articles"
        },
        %Resource{
          attributes: %{
            "title" => "Rails is Omakase"
          },
          id: "2",
          type: "articles"
        }
      ],
      links: %{
        "self" => "http://example.com/articles"
      }
    }
    assert_idempotent document, error_template
  end

  test "fetching resources responses 200 empty collection" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "http://example.com/articles"
      },
      "data": []
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [],
      links: %{
        "self" => "http://example.com/articles"
      }
    }
    assert_idempotent document, error_template
  end

  test "fetching resource response 200 individual" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "http://example.com/articles/1"
      },
      "data": {
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!"
        },
        "relationships": {
          "author": {
            "links": {
              "related": "http://example.com/articles/1/author"
            }
          }
        }
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        attributes: %{
          "title" => "JSON API paints my bikeshed!"
        },
        id: "1",
        relationships: %{
          "author" => %Relationship{
            links: %{
              "related" => "http://example.com/articles/1/author"
            }
          }
        },
        type: "articles"
      },
      links: %{
        "self" => "http://example.com/articles/1"
      }
    }
    assert_idempotent document, error_template
  end

  test "fetching resource response 200 empty" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "http://example.com/articles/1/author"
      },
      "data": null
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: nil,
      links: %{
        "self" => "http://example.com/articles/1/author"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#fetching-relationships-responses-200

  test "fetching present to-one relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "/articles/1/relationships/author",
        "related": "/articles/1/author"
      },
      "data": {
        "type": "people",
        "id": "12"
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %ResourceIdentifier{
        id: "12",
        type: "people"
      },
      links: %{
        "related" => "/articles/1/author",
        "self" => "/articles/1/relationships/author"
      }
    }
    assert_idempotent document, error_template
  end

  test "fetching empty to-one relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "/articles/1/relationships/author",
        "related": "/articles/1/author"
      },
      "data": null
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: nil,
      links: %{
        "related" => "/articles/1/author",
        "self" => "/articles/1/relationships/author"
      }
    }
    assert_idempotent document, error_template
  end

  test "fetching present to-many relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "/articles/1/relationships/tags",
        "related": "/articles/1/tags"
      },
      "data": [
        {"type": "tags", "id": "2"},
        {"type": "tags", "id": "3"}
      ]
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document ==  %Document{
      data: [
        %ResourceIdentifier{
          id: "2",
          type: "tags"
        },
        %ResourceIdentifier{
          id: "3",
          type: "tags"
        }
      ],
      links: %{
        "related" => "/articles/1/tags",
        "self" => "/articles/1/relationships/tags"
      }
    }
    assert_idempotent document, error_template
  end

  test "fetching empty to-many relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "links": {
        "self": "/articles/1/relationships/tags",
        "related": "/articles/1/tags"
      },
      "data": []
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [],
      links: %{
        "related" => "/articles/1/tags",
        "self" => "/articles/1/relationships/tags"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-creating

  test "creating resource" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "photos",
        "attributes": {
          "title": "Ember Hamster",
          "src": "http://example.com/images/productivity.png"
        },
        "relationships": {
          "photographer": {
            "data": {"type": "people", "id": "9"}
          }
        }
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :create, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        attributes: %{
          "src" => "http://example.com/images/productivity.png",
          "title" => "Ember Hamster"
        },
        relationships: %{
          "photographer" => %Relationship{
            data: %ResourceIdentifier{
              id: "9",
              type: "people"
            }
          }
        },
        type: "photos"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-creating-client-ids

  test "client generate ids" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "photos",
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "attributes": {
          "title": "Ember Hamster",
          "src": "http://example.com/images/productivity.png"
        }
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :create, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        attributes: %{
          "src" => "http://example.com/images/productivity.png",
          "title" => "Ember Hamster"},
        id: "550e8400-e29b-41d4-a716-446655440000",
        type: "photos"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-creating-responses-201

  test "created" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "photos",
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "attributes": {
          "title": "Ember Hamster",
          "src": "http://example.com/images/productivity.png"
        },
        "links": {
          "self": "http://example.com/photos/550e8400-e29b-41d4-a716-446655440000"
        }
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :create, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        attributes: %{
          "src" => "http://example.com/images/productivity.png",
          "title" => "Ember Hamster"
        },
        id: "550e8400-e29b-41d4-a716-446655440000",
        links: %{
          "self" => "http://example.com/photos/550e8400-e29b-41d4-a716-446655440000"
        },
        type: "photos"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-updating

  test "updating single resource" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "To TDD or Not"
        }
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :update, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        attributes: %{
          "title" => "To TDD or Not"
        },
        id: "1",
        type: "articles"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-updating-resource-attributes

  test "updating a resources attributes" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "To TDD or Not",
          "text": "TLDR; It's complicated... but check your test coverage regardless."
        }
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :update, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        attributes: %{
          "text" => "TLDR; It's complicated... but check your test coverage regardless.",
          "title" => "To TDD or Not"
        },
        id: "1",
        type: "articles"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-updating-resource-relationships

  test "updating a resource's to-one relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "articles",
        "id": "1",
        "relationships": {
          "author": {
            "data": {"type": "people", "id": "1"}
          }
        }
      }
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :update, "sender" => :client}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        id: "1",
        relationships: %{
          "author" => %Relationship{
            data: %ResourceIdentifier{
              id: "1",
              type: "people"
            }
          }
        },
        type: "articles"
      }
    }
    assert_idempotent document, error_template
  end

  test "updating a resource's to-many relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "articles",
        "id": "1",
        "relationships": {
          "tags": {
            "data": [
              {"type": "tags", "id": "2"},
              {"type": "tags", "id": "3"}
            ]
          }
        }
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :update, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        id: "1",
        relationships: %{
          "tags" => %Relationship{
            data: [
              %ResourceIdentifier{
                id: "2",
                type: "tags"
              },
              %ResourceIdentifier{
                id: "3",
                type: "tags"
              }
            ]
          }
        },
        type: "articles"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-updating-to-one-relationships

  test "updating to-one relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {"type": "people", "id": "12"}
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :update, "sender" => :client}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %ResourceIdentifier{
        id: "12",
        type: "people"
      }
    }
    assert_idempotent document, error_template
  end

  test "clearing to-one relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": null
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :update, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: nil
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/format/#crud-updating-to-many-relationships

  test "updating to-many relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": [
        {"type": "tags", "id": "2"},
        {"type": "tags", "id": "3"}
      ]
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :update, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %ResourceIdentifier{
          id: "2",
          type: "tags"
        },
        %ResourceIdentifier{
          id: "3",
          type: "tags"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  test "clearing to-many relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": []
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :update, "sender" => :client } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: []
    }
    assert_idempotent document, error_template
  end

  test "posting to-many relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": [
        {"type": "comments", "id": "123"}
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :update, "sender" => :client}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %ResourceIdentifier{
          id: "123",
          type: "comments"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  test "deleting to-many relationship" do
    {:ok, decoded} = Poison.decode """
    {
      "data": [
        {"type": "comments", "id": "12"},
        {"type": "comments", "id": "13"}
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :delete, "sender" => :client}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %ResourceIdentifier{
          id: "12",
          type: "comments"
        },
        %ResourceIdentifier{
          id: "13",
          type: "comments"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/recommendations/#asynchronous-processing

  test "asynchronous processing" do
    {:ok, decoded} = Poison.decode """
    {
      "data": {
        "type": "queue-jobs",
        "id": "5234",
        "attributes": {
          "status": "Pending request, waiting other process"
        },
        "links": {
          "self": "/photos/queue-jobs/5234"
        }
      }
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :create, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: %Resource{
        attributes: %{
          "status" => "Pending request, waiting other process"
        },
        id: "5234",
        links: %{
          "self" => "/photos/queue-jobs/5234"
        },
        type: "queue-jobs"
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/examples/#sparse-fieldsets

  test "sparse fieldset with include" do
    {:ok, decoded} = Poison.decode """
    {
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!",
          "body": "The shortest article. Ever.",
          "created": "2015-05-22T14:56:29.000Z",
          "updated": "2015-05-22T14:56:28.000Z"
        },
        "relationships": {
          "author": {
            "data": {"id": "42", "type": "people"}
          }
        }
      }],
      "included": [
        {
          "type": "people",
          "id": "42",
          "attributes": {
            "name": "John",
            "age": 80,
            "gender": "male"
          }
        }
      ]
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %Resource{
          attributes: %{
            "body" => "The shortest article. Ever.",
            "created" => "2015-05-22T14:56:29.000Z",
            "title" => "JSON API paints my bikeshed!",
            "updated" => "2015-05-22T14:56:28.000Z"
          },
          id: "1",
          relationships: %{
            "author" => %Relationship{
              data: %ResourceIdentifier{
                id: "42",
                type: "people"
              }
            }
          },
          type: "articles"
        }
      ],
      included: [
        %Resource{
          attributes: %{
            "age" => 80,
            "gender" => "male",
            "name" => "John"
          },
          id: "42",
          type: "people"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  test "sparse fieldset with include and fields" do
    {:ok, decoded} = Poison.decode """
    {
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!",
          "body": "The shortest article. Ever."
        },
        "relationships": {
          "author": {
            "data": {"id": "42", "type": "people"}
          }
        }
      }],
      "included": [
        {
          "type": "people",
          "id": "42",
          "attributes": {
            "name": "John"
          }
        }
      ]
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %Resource{
          attributes: %{
            "body" => "The shortest article. Ever.",
            "title" => "JSON API paints my bikeshed!"
          },
          id: "1",
          relationships: %{
            "author" => %Relationship{
              data: %ResourceIdentifier{
                id: "42",
                type: "people"
              }
            }
          },
          type: "articles"
        }
      ],
      included: [
        %Resource{
          attributes: %{
            "name" => "John"
          },
          id: "42",
          type: "people"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  test "sparse fields with fields" do
    {:ok, decoded} = Poison.decode """
    {
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!",
          "body": "The shortest article. Ever."
        }
      }],
      "included": [
        {
          "type": "people",
          "id": "42",
          "attributes": {
            "name": "John"
          }
        }
      ]
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %Resource{
          attributes: %{
            "body" => "The shortest article. Ever.",
            "title" => "JSON API paints my bikeshed!"
          },
          id: "1",
          type: "articles"
        }
      ],
      included: [
        %Resource{
          attributes: %{
            "name" => "John"
          },
          id: "42",
          type: "people"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/examples/#pagination

  test "pagination links" do
    {:ok, decoded} = Poison.decode """
    {
      "meta": {
        "total-pages": 13
      },
      "data": [
        {
          "type": "articles",
          "id": "3",
          "attributes": {
            "title": "JSON API paints my bikeshed!",
            "body": "The shortest article. Ever.",
            "created": "2015-05-22T14:56:29.000Z",
            "updated": "2015-05-22T14:56:28.000Z"
          }
        }
      ],
      "links": {
        "self": "http://example.com/articles?page[number]=3&page[size]=1",
        "first": "http://example.com/articles?page[number]=1&page[size]=1",
        "prev": "http://example.com/articles?page[number]=2&page[size]=1",
        "next": "http://example.com/articles?page[number]=4&page[size]=1",
        "last": "http://example.com/articles?page[number]=13&page[size]=1"
      }
    }
    """
    error_template = %Error{ @error_template | meta: %{ "action" => :fetch, "sender" => :server } }
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      data: [
        %Resource{
          attributes: %{
            "body" => "The shortest article. Ever.",
            "created" => "2015-05-22T14:56:29.000Z",
            "title" => "JSON API paints my bikeshed!",
            "updated" => "2015-05-22T14:56:28.000Z"
          },
          id: "3",
          type: "articles"
        }
      ],
      links: %{
        "first" => "http://example.com/articles?page[number]=1&page[size]=1",
        "last" => "http://example.com/articles?page[number]=13&page[size]=1",
        "next" => "http://example.com/articles?page[number]=4&page[size]=1",
        "prev" => "http://example.com/articles?page[number]=2&page[size]=1",
        "self" => "http://example.com/articles?page[number]=3&page[size]=1"
      },
      meta: %{
        "total-pages" => 13
      }
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/examples/#error-objects

  test "basic error object" do
    {:ok, decoded} = Poison.decode """
    {
      "errors": [
        {
          "status": "422",
          "source": {"pointer": "/data/attributes/first-name"},
          "title":  "Invalid Attribute",
          "detail": "First name must contain at least three characters."
        }
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :create, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      errors: [
        %Error{
          detail: "First name must contain at least three characters.",
          source: %Source{
            pointer: "/data/attributes/first-name"
          },
          status: "422",
          title: "Invalid Attribute"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/examples/#error-objects-multiple-errors

  test "multiple errors on different attributes" do
    {:ok, decoded} = Poison.decode """
    {
      "errors": [
        {
          "status": "403",
          "source": {"pointer": "/data/attributes/secret-powers"},
          "detail": "Editing secret powers is not authorized on Sundays."
        },
        {
          "status": "422",
          "source": {"pointer": "/data/attributes/volume"},
          "detail": "Volume does not, in fact, go to 11."
        },
        {
          "status": "500",
          "source": {"pointer": "/data/attributes/reputation"},
          "title": "The backend responded with an error",
          "detail": "Reputation service not responding after three requests."
        }
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :update, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      errors: [
        %Error{
          detail: "Editing secret powers is not authorized on Sundays.",
          source: %Source{
            pointer: "/data/attributes/secret-powers"
          },
          status: "403"
        },
        %Error{
          detail: "Volume does not, in fact, go to 11.",
          source: %Source{
            pointer: "/data/attributes/volume"
          },
          status: "422"
        },
        %Error{
          detail: "Reputation service not responding after three requests.",
          source: %Source{
            pointer: "/data/attributes/reputation"
          },
          status: "500",
          title: "The backend responded with an error"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  test "multiple errors on same attribute" do
    {:ok, decoded} = Poison.decode """
    {
      "errors": [
        {
          "source": {"pointer": "/data/attributes/first-name"},
          "title": "Invalid Attribute",
          "detail": "First name must contain at least three characters."
        },
        {
          "source": {"pointer": "/data/attributes/first-name"},
          "title": "Invalid Attribute",
          "detail": "First name must contain an emoji."
        }
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :create, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      errors: [
        %Error{
          detail: "First name must contain at least three characters.",
          source: %Source{
            pointer: "/data/attributes/first-name"
          },
          title: "Invalid Attribute"
        },
        %Error{
          detail: "First name must contain an emoji.",
          source: %Source{
            pointer: "/data/attributes/first-name"
          },
          title: "Invalid Attribute"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/examples/#error-objects-error-codes

  test "error codes" do
    {:ok, decoded} = Poison.decode """
    {
      "jsonapi": {"version": "1.0"},
      "errors": [
        {
          "code":   "123",
          "source": {"pointer": "/data/attributes/first-name"},
          "title":  "Value is too short",
          "detail": "First name must contain at least three characters."
        },
        {
          "code":   "225",
          "source": {"pointer": "/data/attributes/password"},
          "title": "Passwords must contain a letter, number, and punctuation character.",
          "detail": "The password provided is missing a punctuation character."
        },
        {
          "code":   "226",
          "source": {"pointer": "/data/attributes/password"},
          "title": "Password and password confirmation do not match."
        }
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :create, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      errors: [
        %Error{
          code: "123",
          detail: "First name must contain at least three characters.",
          source: %Source{
            pointer: "/data/attributes/first-name"
          },
          title: "Value is too short"
        },
        %Error{
          code: "225",
          detail: "The password provided is missing a punctuation character.",
          source: %Source{
            pointer: "/data/attributes/password"
          },
          title: "Passwords must contain a letter, number, and punctuation character."
        },
        %Error{
          code: "226",
          source: %Source{
            pointer: "/data/attributes/password"
          },
          title: "Password and password confirmation do not match."
        }
      ]
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/examples/#error-objects-source-usage

  test "advanced source usage" do
    {:ok, decoded} = Poison.decode """
    {
      "errors": [
        {
          "source": {"pointer": ""},
          "detail":  "Missing `data` Member at document's top level."
        }
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :create, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      errors: [
        %Error{
          detail: "Missing `data` Member at document's top level.",
          source: %Source{
            pointer: ""
          }
        }
      ]
    }
    assert_idempotent document, error_template
  end

  test "invalid JSON" do
    {:ok, decoded} = Poison.decode """
    {
      "errors": [{
        "status": "400",
        "detail": "JSON parse error - Expecting property name at line 1 column 2 (char 1)."
      }]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :create, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      errors: [
        %Error{
          detail: "JSON parse error - Expecting property name at line 1 column 2 (char 1).",
          status: "400"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  ## See http://jsonapi.org/examples/#error-objects-invalid-query-parameters

  test "invalid query parameters" do
    {:ok, decoded} = Poison.decode """
    {
      "errors": [
        {
          "source": {"parameter": "include"},
          "title":  "Invalid Query Parameter",
          "detail": "The resource does not have an `auther` relationship path."
        }
      ]
    }
    """
    error_template = %Error{@error_template | meta: %{"action" => :create, "sender" => :server}}
    {:ok, document} = Document.from_json(decoded, error_template)

    assert document == %Document{
      errors: [
        %Error{
          detail: "The resource does not have an `auther` relationship path.",
          source: %Source{
            parameter: "include"
          },
          title: "Invalid Query Parameter"
        }
      ]
    }
    assert_idempotent document, error_template
  end

  # Private Functions

  defp assert_idempotent(start, error_template \\ @error_template)

  defp assert_idempotent(original = %Document{}, error_template) do
    FromJsonCase.assert_idempotent error_template: error_template,
                                   module: Document,
                                   original: original
  end

  defp assert_idempotent(encoded_json, error_template) do
    {:ok, decoded} = Poison.decode(encoded_json)
    {:ok, document} = Document.from_json(decoded, error_template)

    assert_idempotent(document)
  end
end
