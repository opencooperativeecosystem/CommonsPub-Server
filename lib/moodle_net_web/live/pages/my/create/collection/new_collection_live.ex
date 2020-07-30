defmodule MoodleNetWeb.My.NewCollectionLive do
  use MoodleNetWeb, :live_component

  import MoodleNetWeb.Helpers.Common

  # alias MoodleNetWeb.Helpers.{Profiles, Communities}

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end

  def handle_event("toggle_collection", _data, socket) do
    {:noreply, assign(socket, :toggle_collection, !socket.assigns.toggle_collection)}
  end

  def handle_event("new_collection", %{"name" => name, "context_id" => context_id} = data, socket) do
    if(is_nil(name) or !Map.has_key?(socket.assigns, :current_user)) do
      {:noreply,
       socket
       |> put_flash(:error, "Please enter a name...")}
    else
      collection = input_to_atoms(data)
      IO.inspect(data, label: "collection to create")

      {:ok, collection} =
        MoodleNetWeb.GraphQL.CollectionsResolver.create_collection(
          %{collection: collection, context_id: context_id},
          %{context: %{current_user: socket.assigns.current_user}}
        )

      # TODO: handle errors
      IO.inspect(collection, label: "collection created")

      if(!is_nil(collection) and collection.actor.preferred_username) do
        {:noreply,
         socket
         |> put_flash(:info, "collection created !")
         # change redirect
         |> push_redirect(to: "/+" <> collection.actor.preferred_username)}
      else
        {:noreply,
         socket
         |> push_redirect(to: "/instance/collections/")}
      end
    end
  end
end
