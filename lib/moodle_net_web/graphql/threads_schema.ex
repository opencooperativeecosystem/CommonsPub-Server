# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.ThreadsSchema do
  use Absinthe.Schema.Notation
  alias MoodleNetWeb.GraphQL.{
    CommonResolver,
    FollowsResolver,
    ThreadsResolver,
    UsersResolver,
  }
  alias MoodleNet.Communities.Community
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Flags.Flag
  alias MoodleNet.Resources.Resource

  object :threads_queries do

    @desc "Get a thread"
    field :thread, :thread do
      arg :thread_id, non_null(:string)
      resolve &ThreadsResolver.thread/2
    end

  end

  object :threads_mutations do

    @desc "Create a new thread"
    field :create_thread, :comment do
      arg :context_id, non_null(:string)
      arg :comment, non_null(:comment_input)
      resolve &ThreadsResolver.create_thread/2
    end

  end

  @desc "A thread is essentially a list of comments"
  object :thread do
    @desc "An instance-local UUID identifying the thread"
    field :id, non_null(:string)
    @desc "A url for the user, may be to a remote instance"
    field :canonical_url, :string

    @desc "Whether the thread is local to the instance"
    field :is_local, non_null(:boolean)
    @desc "Whether the thread is publically visible"
    field :is_public, non_null(:boolean) do
      resolve &CommonResolver.is_public_edge/3
    end
    @desc "Whether an instance admin has hidden the thread"
    field :is_hidden, non_null(:boolean) do
      resolve &CommonResolver.is_hidden_edge/3
    end

    @desc "When the thread was created"
    field :created_at, non_null(:string) do
      resolve &CommonResolver.created_at_edge/3
    end
    @desc "When the thread was last updated"
    field :updated_at, non_null(:string)
    @desc "The last time the thread or a comment on it was created or updated"
    field :last_activity, non_null(:string) do
      resolve &ThreadsResolver.last_activity_edge/3
    end

    @desc "The current user's follow of the community, if any"
    field :my_follow, :follow do
      resolve &FollowsResolver.my_follow_edge/3
    end

    @desc "The object the thread is attached to"
    field :context, non_null(:thread_context) do
      resolve &CommonResolver.context_edge/3
    end

    @desc "Comments in the thread, most recently created first"
    field :comments, non_null(:comments_edges) do
      arg :limit, :integer
      arg :before, :string
      arg :after,  :string
      resolve &ThreadsResolver.comments_edge/3
    end

    @desc "Users following the collection, most recently followed first"
    field :followers, non_null(:follows_edges) do
      arg :limit, :integer
      arg :before, :string
      arg :after,  :string
      resolve &FollowsResolver.followers_edge/3
    end

  end
    
  union :thread_context do
    description "The thing the comment is about"
    types [:collection, :community, :flag, :resource]
    resolve_type fn
      %Collection{}, _ -> :collection
      %Community{},  _ -> :community
      %Flag{},       _ -> :flag
      %Resource{},   _ -> :resource
    end
  end

  object :threads_nodes do
    field :page_info, :page_info
    field :nodes, non_null(list_of(:threads_edge))
    field :total_count, non_null(:integer)
  end

  object :threads_edges do
    field :page_info, :page_info
    field :edges, list_of(:threads_edge)
    field :total_count, non_null(:integer)
  end

  object :threads_edge do
    field :cursor, non_null(:string)
    field :node, non_null(:thread)
  end

end
