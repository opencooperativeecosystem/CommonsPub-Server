# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Resources.Resource do
  use MoodleNet.Common.Schema

  import MoodleNet.Common.Changeset,
    only: [change_public: 1, change_disabled: 1, cast_object: 1]

  alias Ecto.Changeset
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Resources
  alias MoodleNet.Resources.Resource
  alias MoodleNet.Uploads.Content
  alias MoodleNet.Users.User

  table_schema "mn_resource" do
    belongs_to(:creator, User)
    # TODO: replace by context
    belongs_to(:collection, Collection)
    belongs_to(:context, Pointers.Pointer)
    belongs_to(:content, Content)
    belongs_to(:icon, Content)

    # belongs_to(:primary_language, Language, type: :binary)

    field(:canonical_url, :string)

    field(:name, :string)
    field(:summary, :string)

    field(:license, :string)

    field(:author, :string)
    field(:level, :string)
    field(:subject, :string)
    field(:language, :string)
    field(:type, :string)

    field(:extra_info, :map)

    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:is_disabled, :boolean, virtual: true)
    field(:disabled_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)

    timestamps()
  end

  @required ~w(name content_id creator_id)a
  @cast @required ++
          ~w(canonical_url is_public is_disabled license summary icon_id author subject level language type)a

  @spec create_changeset(User.t(), Collection.t(), map) :: Changeset.t()
  def create_changeset(creator, %Collection{} = collection, attrs) do
    %Resource{}
    |> Changeset.cast(attrs, @cast)
    |> cast_object()
    |> Changeset.change(
      # collection_id is being deprecated in favour of context_id
      collection_id: collection.id,
      context_id: collection.id,
      creator_id: creator.id,
      is_public: true
    )
    |> Changeset.validate_required(@required)
    |> common_changeset()
  end

  @doc "Creates a changeset for insertion of a resource with the given attributes."
  def create_changeset(creator, context, attrs) do
    %Resource{}
    |> Changeset.cast(attrs, @cast)
    |> cast_object()
    |> Changeset.change(
      context_id: context.id,
      creator_id: creator.id,
      is_public: true
    )
    |> Changeset.validate_required(@required)
    |> common_changeset()
  end

  def create_changeset(creator, attrs) do
    %Resource{}
    |> Changeset.cast(attrs, @cast)
    |> cast_object()
    |> Changeset.change(
      creator_id: creator.id,
      is_public: true
    )
    |> Changeset.validate_required(@required)
    |> common_changeset()
  end

  @spec update_changeset(%Resource{}, map) :: Changeset.t()
  @doc "Creates a changeset for updating the resource with the given attributes."
  def update_changeset(%Resource{} = resource, attrs) do
    resource
    |> Changeset.cast(attrs, @cast)
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    |> change_disabled()
    |> change_public()
  end

  ### behaviour callbacks

  def context_module, do: Resources

  def queries_module, do: Resources.Queries

  def follow_filters, do: []
end
