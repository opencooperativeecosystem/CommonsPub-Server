# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Mail.Email do
  @moduledoc """
  Email Bamboo module
  """
  import MoodleNetWeb.Gettext
  use Bamboo.Phoenix, view: MoodleNetWeb.EmailView

  def welcome(user, token) do
    url = email_confirmation_url(user.id, token.id)
    base_email(user)
    |> subject(gettext("Welcome to MoodleNet"))
    |> render(:welcome, user: user, url: url)
  end

  def reset_password_request(user, token) do
    url = reset_password_url(token.id)
    base_email(user)
    |> subject(gettext("Did you forget your MoodleNet password?"))
    |> render(:reset_password_request, user: user, url: url)
  end

  def password_reset(user) do
    base_email(user)
    |> subject(gettext("Your MoodleNet password has been reset"))
    |> render(:password_reset)
  end

  def invite(email) do
    url = invite_url(email)
    base_email_by_address(email)
    |> subject(gettext("You have been invited to MoodleNet!"))
    |> render(:invite, url: url)
  end

  defp base_email(user) do
    new_email()
    |> to(user.local_user.email)
    |> from(reply_to_email())
    |> put_layout({MoodleNetWeb.LayoutView, :email})
  end

  defp base_email_by_address(email) do
    new_email()
    |> to(email)
    |> from(reply_to_email())
    |> put_layout({MoodleNetWeb.LayoutView, :email})
  end

  defp email_confirmation_url(_id, token),
    do: frontend_url("confirm-email/#{token}")

  defp reset_password_url(token), do: frontend_url("reset/#{token}")

  defp invite_url(email), do: frontend_url("signup?email=#{email}")

  # Note that the base url is expected to end without a slash (/)
  defp frontend_url(path) do
    Application.fetch_env!(:moodle_net, :frontend_base_url) <> "/" <> path
  end

  defp reply_to_email do
    Application.fetch_env!(:moodle_net, MoodleNet.Mail.MailService)
    |> Keyword.get(:reply_to, "no-reply@moodle.net")
  end
end
