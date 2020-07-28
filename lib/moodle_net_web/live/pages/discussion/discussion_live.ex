defmodule MoodleNetWeb.DiscussionLive do
  use MoodleNetWeb, :live_view
  import MoodleNetWeb.Helpers.Common
  alias MoodleNetWeb.GraphQL.{ThreadsResolver, CommentsResolver}

  alias MoodleNetWeb.Helpers.{
    # Account,
    Discussions
  }

  alias MoodleNetWeb.Discussion.DiscussionCommentLive

  def mount(%{"id" => thread_id} = params, session, socket) do
    socket = init_assigns(params, session, socket)

    current_user = socket.assigns.current_user

    {:ok, thread} =
      ThreadsResolver.thread(%{thread_id: thread_id}, %{
        context: %{current_user: current_user}
      })

      thread = Discussions.prepare_thread(thread)
      IO.inspect(thread, label: "Thread")
    # TODO: tree of replies & pagination
    {:ok, comments} =
      CommentsResolver.comments_edge(thread, %{limit: 15}, %{
        context: %{current_user: current_user}
      })

    # comments_edges = comments.edges
    comments_edges = Discussions.prepare_comments(comments.edges, current_user)

    # IO.inspect(comments_edges, label: "COMMENTS")

    tree = Discussions.build_comment_tree(comments_edges)

    # IO.inspect(tree: tree)

    {main_comment_id, _} = Enum.fetch!(tree, 0)

    {:ok,
     assign(socket,
       #  current_user: current_user,
       reply_to: main_comment_id,
       thread: thread,
       #  main_comment: main_comment,
       comments: tree
     )}
  end

  def handle_params(
        %{"id" => thread_id, "sub_id" => comment_id} = params,
        session,
        socket
      ) do
        IO.inspect(comment_id, label: "commenidt")

    {_, reply_comment} =  Enum.find(socket.assigns.comments, fn(element) ->
      {_id, comment} = element
      IO.inspect(comment.id, label: "comment")
      comment.id == comment_id
    end)

    IO.inspect(reply_comment, label: "test")

    {:noreply,
     assign(socket,
       reply_to: comment_id,
       reply: reply_comment
     )}
  end

  def handle_params(%{"id" => thread_id} = params, session, socket) do
    {:noreply,
     assign(socket,
       reply_to: nil,
       reply: nil
     )}
  end

  def handle_event("reply", %{"content" => content} = data, socket) do
    # IO.inspect(data, label: "DATA")

    if(is_nil(content) or is_nil(socket.assigns.current_user)) do
      {:noreply,
       socket
       |> put_flash(:error, "Please write something...")}
    else
      # MoodleNetWeb.Plugs.Auth.login(socket, session.current_user, session.token)

      comment = input_to_atoms(data)

      reply_to_id =
        if !is_nil(socket.assigns.reply_to) do
          socket.assigns.reply_to
          # else
          #   socket.assigns.main_comment.id
        end

      {:ok, comment} =
        MoodleNetWeb.GraphQL.CommentsResolver.create_reply(
          %{
            thread_id: socket.assigns.thread.id,
            in_reply_to_id: reply_to_id,
            comment: comment
          },
          %{context: %{current_user: socket.assigns.current_user}}
        )

      # IO.inspect(comment, label: "HERE")

      # TODO: error handling

      {:noreply,
       socket
       |> put_flash(:info, "Replied!")
       # redirect in order to reload comments, TODO: just add comment which was returned by resolver?
       |> push_redirect(to: "/!" <> socket.assigns.thread.id <> "/discuss/" <> comment.id)}
    end
  end
end
