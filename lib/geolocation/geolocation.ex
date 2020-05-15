defmodule Geolocation do

  use MoodleNet.Common.Schema
  
  import MoodleNet.Common.Changeset, only: [change_public: 1, change_disabled: 1]

  alias Ecto.Changeset
  alias MoodleNet.Users.User
  alias MoodleNet.Actors.Actor
  alias MoodleNet.Meta.Pointer

  @type t :: %__MODULE__{}

  table_schema "geolocation" do
    field :name, :string

    field :point, Geo.PostGIS.Geometry
    field :alt, :float # altitude
    field :mappable_address, :string
    field :note, :string

    field(:lat, :float, virtual: true)
    field(:long, :float, virtual: true)

    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:is_disabled, :boolean, virtual: true, default: false)
    field(:disabled_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)

    belongs_to(:actor, Actor)
    belongs_to(:creator, User)
    # belongs_to(:community, Community)
    belongs_to(:context, Pointer)

    belongs_to(:inbox_feed, Feed, foreign_key: :inbox_id)
    belongs_to(:outbox_feed, Feed, foreign_key: :outbox_id)
    field(:follower_count, :any, virtual: true) # because it's keyed by pointer

    timestamps()
  end

  @required ~w(name)a
  @cast @required ++ ~w(note mappable_address point alt is_disabled inbox_id outbox_id)a

  def create_changeset(
        %User{} = creator,
        %{id: _} = context,
        %Actor{} = actor,
        attrs
      ) do
      %__MODULE__{}
        |> Changeset.cast(attrs, @cast)
        |> Changeset.validate_required(@required)
        |> Changeset.change(
          creator_id: creator.id,
          context_id: context.id,
          actor_id: actor.id,
          is_public: true
      )
    |> common_changeset()
  end

  def create_changeset(
    %User{} = creator,
    %Actor{} = actor,
    attrs
  ) do
  %__MODULE__{}
    |> Changeset.cast(attrs, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.change(
      creator_id: creator.id,
      actor_id: actor.id,
      is_public: true
    )
    |> common_changeset()
  end


  def update_changeset(%__MODULE__{} = geolocation, attrs) do
    geolocation
    |> Changeset.cast(attrs, @cast)
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    |> change_public()
    |> change_disabled()
  end

end
