# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Likes.LikeCount do
  use MoodleNet.Common.Schema
  alias MoodleNet.Users.User

  view_schema "mn_like_count" do
    belongs_to(:creator, User, primary_key: true)
    field(:count, :integer)
  end
end
