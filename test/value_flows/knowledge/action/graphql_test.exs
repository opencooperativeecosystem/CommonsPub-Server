defmodule Valueflows.Knowledge.Action.GraphQLTest do
  use CommonsPub.Web.ConnCase, async: true

  import CommonsPub.Test.Faking
  import CommonsPub.Utils.Simulation

  import ValueFlows.Simulate
  import ValueFlows.Test.Faking

  describe "action" do
    test "fetches an existing action by label" do
      user = fake_user!()
      action = action()

      q = action_query()
      conn = user_conn(user)
      assert_action(grumble_post_key(q, conn, :action, %{id: action.label}))
    end
  end

  describe "actions" do
    test "fetches all actions" do
      user = fake_user!()
      actions = actions()
      q = actions_query()
      conn = user_conn(user)

      assert actions = grumble_post_key(q, conn, :actions, %{})
      assert Enum.count(actions) > 1
    end
  end

end
