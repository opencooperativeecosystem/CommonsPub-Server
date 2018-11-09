defmodule MoodleNetWeb.OAuth.OAuthControllerTest do
  use MoodleNetWeb.ConnCase
  alias MoodleNet.NewFactory, as: Factory

  describe "create" do
    test "creates app", %{conn: conn} do
      params = Factory.attributes(:oauth_app)

      assert app =
               conn
               |> post("/oauth/apps/", %{"app" => params})
               |> json_response(201)

      assert app["client_name"] == params["client_name"]
      assert app["client_id"] == params["client_id"]
      assert app["redirect_uri"] == params["redirect_uri"]
      assert app["website"] == params["website"]
      assert app["scopes"] == params["scopes"]
      assert app["client_secret"]
    end

    test "returns errors", %{conn: conn} do
      params = Factory.attributes(:oauth_app, redirect_uri: "https://very_random.com")

      assert error =
               conn
               |> post("/oauth/apps/", %{"app" => params})
               |> json_response(422)

      assert error == %{
               "error_code" => "validation_errors",
               "error_message" => "Validation errors",
               "errors" => %{
                 "redirect_uri" => ["must have the same scheme, host and port that client_id"]
               }
             }

      assert error =
               conn
               |> post("/oauth/apps/")
               |> json_response(422)

      assert error == %{"error_code" => "missing_param", "error_message" => "Param not found: app"}
    end
  end
end
