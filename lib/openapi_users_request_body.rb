# frozen_string_literal: true

# rswag duplicates the JSON body schema onto multipart/form-data.
# Patch PATCH /api/v1/me so mobile clients see flat user[...] parts + binary avatar.
module OpenapiUsersRequestBody
  module_function

  JSON_SCHEMA = {
    "type" => "object",
    "required" => [ "user" ],
    "properties" => {
      "user" => {
        "type" => "object",
        "description" => "JSON: text fields only. For avatar file use multipart user[avatar].",
        "properties" => {
          "first_name" => { "type" => "string" },
          "last_name" => { "type" => "string" },
          "email" => { "type" => "string", "format" => "email" },
          "password" => { "type" => "string", "format" => "password", "minLength" => 6, "maxLength" => 128 },
          "password_confirmation" => { "type" => "string", "format" => "password" },
          "remove_avatar" => {
            "type" => "boolean",
            "description" => "When true, clears avatar; avatar_url becomes null."
          }
        }
      }
    },
    "example" => { "user" => { "first_name" => "Updated" } }
  }.freeze

  MULTIPART_SCHEMA = {
    "type" => "object",
    "properties" => {
      "user[first_name]" => { "type" => "string" },
      "user[last_name]" => { "type" => "string" },
      "user[email]" => { "type" => "string", "format" => "email" },
      "user[password]" => { "type" => "string", "format" => "password", "minLength" => 6, "maxLength" => 128 },
      "user[password_confirmation]" => { "type" => "string", "format" => "password" },
      "user[avatar]" => {
        "type" => "string",
        "format" => "binary",
        "description" => "Profile photo file (jpg, jpeg, gif, png)."
      },
      "user[remove_avatar]" => {
        "type" => "boolean",
        "description" => "When true, clears avatar; avatar_url becomes null."
      }
    }
  }.freeze

  def patch!(document)
    patch_op = document.dig("paths", "/api/v1/me", "patch")
    return document unless patch_op

    patch_op["requestBody"] = {
      "required" => true,
      "content" => {
        "application/json" => { "schema" => JSON_SCHEMA },
        "multipart/form-data" => { "schema" => MULTIPART_SCHEMA }
      }
    }
    document
  end
end
