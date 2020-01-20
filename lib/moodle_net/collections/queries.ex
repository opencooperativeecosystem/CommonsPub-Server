# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Collections.Queries do

  alias MoodleNet.Communities
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Follows.{Follow, FollowerCount}
  alias MoodleNet.Likes.Like
  alias MoodleNet.Users.{LocalUser, User}

  import Ecto.Query

  def query(Collection) do
    from c in Collection, as: :collection,
      join: a in assoc(c, :actor), as: :actor
  end

  def query(:count) do
    from c in Collection, as: :collection
  end

  def query(q, filters), do: filter(query(q), filters)

  def queries(query, base_filters, data_filters, count_filters) do
    base_q = query(query, base_filters)
    data_q = filter(base_q, data_filters)
    count_q = filter(base_q, count_filters)
    {data_q, count_q}
  end

  def join_to(q, spec, join_qualifier \\ :left)

  def join_to(q, specs, jq) when is_list(specs) do
    Enum.reduce(specs, q, &join_to(&2, &1, jq))
  end

  def join_to(q, :community, jq) do
    join q, jq, [collection: c], c2 in assoc(c, :community), as: :community
  end

  def join_to(q, {:community_follow, follower_id}, jq) do
    join q, jq, [community: c], f in Follow, as: :community_follow,
      on: c.id == f.context_id and f.creator_id == ^follower_id
  end

  def join_to(q, {:follow, follower_id}, jq) do
    join q, jq, [collection: c], f in Follow, as: :follow,
      on: c.id == f.context_id and f.creator_id == ^follower_id
  end

  def join_to(q, :follower_count, jq) do
    join q, jq, [collection: c],
      f in FollowerCount, on: c.id == f.context_id,
      as: :follower_count
  end

  ### filter/2

  ## by many

  def filter(q, filters) when is_list(filters) do
    Enum.reduce(filters, q, &filter(&2, &1))
  end

  ## by join

  def filter(q, {:join, {join, qual}}), do: join_to(q, join, qual)
  def filter(q, {:join, join}), do: join_to(q, join)

  ## by user

  def filter(q, {:user, %User{local_user: %LocalUser{is_instance_admin: true}}}) do
    filter(q, :deleted)
  end

  def filter(q, {:user, %User{id: id}}) do
    q
    |> join_to([:community, follow: id, community_follow: id])
    |> where([community: c, community_follow: f], not is_nil(c.published_at) or not is_nil(f.id))
    |> where([collection: c, follow: f], not is_nil(c.published_at) or not is_nil(f.id))
    |> filter(~w(deleted disabled)a)
    |> Communities.Queries.filter(~w(deleted disabled)a)
  end

  def filter(q, {:user, nil}) do
    q
    |> join_to(:community)
    |> filter(~w(deleted disabled private)a)
    |> Communities.Queries.filter(~w(deleted disabled private)a)
  end

  ## by status
  
  def filter(q, :deleted) do
    where q, [collection: c], is_nil(c.deleted_at)
  end

  def filter(q, :disabled) do
    where q, [collection: c], is_nil(c.disabled_at)
  end

  def filter(q, :private) do
    where q, [collection: c], not is_nil(c.published_at)
  end

  ## by field values

  def filter(q, {:id, id}) when is_binary(id) do
    where q, [collection: c], c.id == ^id
  end

  def filter(q, {:id, ids}) when is_list(ids) do
    where q, [collection: c], c.id in ^ids
  end

  def filter(q, {:community_id, id}) when is_binary(id) do
    where q, [collection: c], c.community_id == ^id
  end

  def filter(q, {:community_id, ids}) when is_list(ids) do
    where q, [collection: c], c.community_id in ^ids
  end

  def filter(q, {:username, username}) when is_binary(username) do
    where q, [actor: a], a.preferred_username == ^username
  end

  def filter(q, {:username, usernames}) when is_list(usernames) do
    where q, [actor: a], a.preferred_username in ^usernames
  end

  ## by ordering

  def filter(q, {:order, :followers_desc}) do
    order_by q, [collection: c, follower_count: fc],
      desc: coalesce(fc.count, 0),
      desc: c.updated_at,
      desc: c.id
  end

  # grouping and counting

  def filter(q, {:group_count, key}) when is_atom(key) do
    filter(q, group: key, count: key)
  end

  def filter(q, {:group, key}) when is_atom(key) do
    group_by(q, [collection: c], field(c, ^key))
  end

  def filter(q, {:count, key}) when is_atom(key) do
    select(q, [collection: c], {field(c, ^key), count(c.id)})
  end

  def filter(q, {:preload, :actor}) do
    preload q, [actor: a], actor: a
  end

  def filter(q, {:preload, :follower_count}) do
    preload q, [actor: a, follower_count: fc], actor: a, follower_count: fc
  end

end
