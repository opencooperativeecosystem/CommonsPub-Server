# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.GraphQL.CommonSchemaTest do
  use MoodleNetWeb.ConnCase, async: true
  alias MoodleNet.Test.Fake

  import MoodleNet.Test.Faking
  import MoodleNetWeb.Test.ConnHelpers
  import MoodleNetWeb.Test.GraphQLAssertions
  import MoodleNetWeb.Test.GraphQLFields

  alias MoodleNet.{Features, Flags, Follows, Likes}

  defp delete_q(id) do
    """
    mutation {
      delete(contextId: \"#{id}\") {
        __typename
        ... on Collection {
          #{collection_basics()}
        }
        ... on Community {
          #{community_basics()}
        }
        ... on Resource {
          #{resource_basics()}
        }
        ... on Thread {
          #{thread_basics()}
        }
        ... on Comment {
          #{comment_basics()}
        }
        ... on Feature {
          #{feature_basics()}
        }
        ... on Follow {
          #{follow_basics()}
        }
        ... on Flag {
          #{flag_basics()}
        }
        ... on Like {
          #{like_basics()}
        }
        ... on User {
          #{user_basics()}
        }
      }
    }
    """
  end

  describe "delete" do
    @tag :skip
    test "works for various types that allow deletion for an admin" do
      user = fake_user!(%{is_instance_admin: true})
      conn = user_conn(user)

      other_user = fake_user!()
      comm = fake_community!(user)
      coll = fake_collection!(user, comm)
      resource = fake_resource!(user, coll)

      for context <- [other_user, comm, coll, resource] do
        query = %{query: delete_q(context.id)}
        assert %{"delete" => res} = gql_post_data(conn, query)
        assert res["__typename"]
        assert res["id"] == context.id
      end

      # assert {:ok, follow} = Follows.create(user, other_user, %{is_local: true})
      # query = %{query: delete_q(follow.id)}
      # assert %{"delete" => res} = gql_post_data(conn, query)
      # assert res["id"] == follow.id

      assert {:ok, like} = Likes.create(user, comm, %{is_local: true})
      query = %{query: delete_q(like.id)}
      assert %{"delete" => res} = gql_post_data(conn, query)
      assert res["id"] == like.id

      assert {:ok, flag} = Flags.create(user, comm, Fake.flag())
      query = %{query: delete_q(flag.id)}
      assert %{"delete" => res} = gql_post_data(conn, query)
      assert res["id"] == flag.id

      assert {:ok, feature} = Features.create(user, comm, %{is_local: true})
      query = %{query: delete_q(feature.id)}
      assert %{"delete" => res} = gql_post_data(conn, query)
      assert res["id"] == feature.id
    end

    test "deleting an item twice" do
      user = fake_user!()
      conn = user_conn(user)

      comm = fake_community!(user)
      assert {:ok, flag} = Flags.create(user, comm, Fake.flag())
      query = %{query: delete_q(flag.id)}

      assert %{"delete" => res} = gql_post_data(conn, query)
      assert res["id"] == flag.id

      assert [%{"code" => "deletion_error", "message" => "was already deleted"}] =
               gql_post_errors(conn, query)
    end

    test "can not delete another user" do
    end

    test "can not delete an item of another user" do
    end
  end
end
