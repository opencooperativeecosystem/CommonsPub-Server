defmodule MoodleNet.OAuth.Token do
  use Ecto.Schema

  alias Ecto.Changeset

  schema "oauth_tokens" do
    field(:hash, :string)
    field(:refresh_hash, :string)
    field(:valid_until, :naive_datetime_usec)
    belongs_to(:user, MoodleNet.Accounts.NewUser)
    belongs_to(:app, MoodleNetWeb.OAuth.App)

    timestamps()
  end

  def build(app_id, user_id) do
    hash = MoodleNet.Token.random_key_with_id(user_id)
    refresh_hash = MoodleNet.Token.random_key_with_id(user_id)

    Changeset.change(%__MODULE__{},
      hash: hash,
      refresh_hash: refresh_hash,
      user_id: user_id,
      app_id: app_id,
      valid_until: expiration_time()
    )
    |> Changeset.validate_required([:user_id, :app_id])
  end

  defp expiration_time(), do: NaiveDateTime.add(NaiveDateTime.utc_now(), 60 * 10)
end
