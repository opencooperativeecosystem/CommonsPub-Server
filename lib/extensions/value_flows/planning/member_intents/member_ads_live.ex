defmodule MoodleNetWeb.MemberLive.MemberAdsLive do
  use MoodleNetWeb, :live_component

  # import MoodleNetWeb.Helpers.Common

  alias MoodleNetWeb.Component.{
    DiscussionPreviewLive,
    AdsPreviewLive
  }

  # alias MoodleNetWeb.Helpers.{Profiles}

  # def mount(socket) do
  #   {
  #     :ok,
  #     socket,
  #     temporary_assigns: [discussions: [], page: 1, has_next_page: false, after: [], before: []]
  #   }
  # end

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> fetch(assigns)
    }
  end

  defp fetch(socket, assigns) do
    # IO.inspect(assigns.user)

    page_opts = %{limit: 10}

    {:ok, ads} =
      ValueFlows.Planning.Intent.GraphQL.fetch_creator_intents_edge(
        page_opts,
        %{context: %{current_user: assigns.current_user}},
        assigns.current_user.id
      )

    IO.inspect(ads, label: "ADS:")

    assign(socket,
      ads: ads.edges,
      has_next_page: ads.page_info.has_next_page,
      after: ads.page_info.end_cursor,
      before: ads.page_info.start_cursor,
      current_user: assigns.current_user
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns)}
  end
end