defmodule ValueFlows.Planning.Intent.Migrations do
  use Ecto.Migration
  # alias CommonsPub.Repo
  # alias Ecto.ULID
  import Pointers.Migration

  alias ValueFlows.Knowledge.ResourceSpecification
  alias ValueFlows.Observation.EconomicResource
  alias ValueFlows.Observation.Process
  alias ValueFlows.Proposal

  defp intent_table(), do: ValueFlows.Planning.Intent.__schema__(:source)

  def up do
    create_pointable_table(ValueFlows.Planning.Intent) do
      add(:name, :string)
      add(:note, :text)

      # array of URI
      add(:resource_classified_as, {:array, :string})

      add(:action_id, :string)

      # optional context as scope
      add(:context_id, weak_pointer(), null: true)

      add(:finished, :boolean, default: false)

      # # field(:deletable, :boolean) # TODO - virtual field? how is it calculated?

      # belongs_to(:agreed_in, Agreement)

      # inverse relationships
      # has_many(:published_in, ProposedIntent)
      # has_many(:satisfied_by, Satisfaction)

      add(:has_beginning, :timestamptz)
      add(:has_end, :timestamptz)
      add(:has_point_in_time, :timestamptz)
      add(:due, :timestamptz)

      add(:published_at, :timestamptz)
      add(:deleted_at, :timestamptz)
      add(:disabled_at, :timestamptz)

      timestamps(inserted_at: false, type: :utc_datetime_usec)
    end
  end

  def add_references do
    alter table(intent_table()) do
      add_if_not_exists(:creator_id, references("mn_user", on_delete: :nilify_all))

      add_if_not_exists(:image_id, references(:mn_content))

      add_if_not_exists(:provider_id, weak_pointer(), null: true)
      add_if_not_exists(:receiver_id, weak_pointer(), null: true)

      add_if_not_exists(:available_quantity_id, weak_pointer(Measurement.Measure), null: true)
      add_if_not_exists(:resource_quantity_id, weak_pointer(Measurement.Measure), null: true)
      add_if_not_exists(:effort_quantity_id, weak_pointer(Measurement.Measure), null: true)

      add_if_not_exists(:input_of_id, weak_pointer(Process), null: true)
      add_if_not_exists(:output_of_id, weak_pointer(Process), null: true)
      add_if_not_exists(:resource_conforms_to_id, weak_pointer(ResourceSpecification), null: true)
      add_if_not_exists(:resource_inventoried_as_id, weak_pointer(EconomicResource), null: true)

      add_if_not_exists(:at_location_id, weak_pointer(Geolocation), null: true)
    end
  end

  def down do
    drop_pointable_table(ValueFlows.Planning.Intent)
  end
end
