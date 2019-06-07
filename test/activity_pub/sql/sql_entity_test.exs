# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.SQLEntityTest do
  use MoodleNet.DataCase, async: true

  alias ActivityPub.SQLEntity
  alias ActivityPub.SQL.Query

  describe "insert" do
    test "works with new entities" do
      map = %{
        type: "Object",
        content: "This is a content",
        name: "This is my name",
        end_time: "2015-01-01T06:00:00-08:00",
        extension_field: "extra"
      }

      assert {:ok, entity} = ActivityPub.new(map)
      assert {:ok, persisted} = SQLEntity.insert(entity)
      refute entity.id
      assert persisted.id
      assert Map.drop(entity, [:__ap__, :id]) == Map.drop(persisted, [:__ap__, :id])
    end

    test "works with new entity assocs" do
      map = %{
        type: "Create",
        summary: "Alex inserted a note",
        actor: %{
          type: "Person",
          name: "Alex",
          preferred_username: "alexcastano",
        },
        object: %{
          type: "Note",
          content: "This is a content",
          end_time: "2015-01-01T06:00:00-08:00",
          extension_field: "extra"
        }
      }

      assert {:ok, entity} = ActivityPub.new(map)
      assert {:ok, persisted} = SQLEntity.insert(entity)
      assert persisted.type == ["Object", "Activity", "Create"]
      assert persisted.summary == %{"und" => map.summary}

      assert [actor] = persisted.actor
      assert actor.name == %{"und" => map.actor.name}
      assert actor.preferred_username == map.actor.preferred_username

      assert [object] = persisted.object
      assert object.content == %{"und" => map.object.content}
      assert %DateTime{} = object.end_time
      assert object["extension_field"] == map.object.extension_field
    end

    test "works with existing entity assocs" do
      assert {:ok, person} = ActivityPub.new(%{
          type: "Person",
          name: "Alex",
          preferred_username: "alexcastano",
        })
      assert {:ok, person} = SQLEntity.insert(person)

      map = %{
        type: "Create",
        summary: "Alex inserted a note",
        actor: person,
        object: %{
          type: "Note",
          content: "This is a content",
          end_time: "2015-01-01T06:00:00-08:00",
          extension_field: "extra"
        }
      }
      assert {:ok, entity} = ActivityPub.new(map)
      assert {:ok, persisted} = SQLEntity.insert(entity)
      assert persisted.type == ["Object", "Activity", "Create"]
      assert persisted.summary == %{"und" => map.summary}

      assert hd(persisted.actor) == person
    end

    test "fails with not loaded assocs" do
      map = %{
        attributed_to: "https://moodle.net/user/alexcastano",
        content: "content"
      }

      assert {:ok, entity} = ActivityPub.new(map)
      assert {:error, %Ecto.Changeset{} = ch} = SQLEntity.insert(entity)
      assert [%{status: _}] = errors_on(ch)[:attributed_to]
    end
  end

  describe "update" do
    test "works" do
      map = %{}
      assert {:ok, entity} = ActivityPub.new(map)
      assert {:ok, persisted} = ActivityPub.insert(entity)
      assert {:ok, updated} = SQLEntity.update(persisted, %{name: %{"en" => "New name"}})
      assert %{"en" => "New name"} == updated.name
      assert %{"en" => "New name"} == Query.reload(updated).name
    end

    test "works with actor aspect" do
      map = %{type: "Person", preferred_username: "Moodle"}
      assert {:ok, entity} = ActivityPub.new(map)
      assert {:ok, persisted} = ActivityPub.insert(entity)
      assert {:ok, updated} = SQLEntity.update(persisted, preferred_username: "MoodleNet")
      assert "MoodleNet" == updated.preferred_username
      assert "MoodleNet" == Query.reload(updated).preferred_username
    end
  end

  describe "delete" do
    test "works" do
      map = %{
        context: %{},
        content: "content"
      }

      assert {:ok, entity} = ActivityPub.new(map)
      assert {:ok, persisted} = ActivityPub.insert(entity)
      assert [context] = persisted.context
      assert :ok = SQLEntity.delete(persisted, [:context])
      refute Query.reload(persisted)
      refute Query.reload(context)
    end
  end
end
