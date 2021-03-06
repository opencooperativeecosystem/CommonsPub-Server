# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Follows.AlreadyFollowingError do
  @enforce_keys [:message, :code, :status]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          message: binary,
          code: binary,
          status: integer
        }

  @doc "Create a new AlreadyFollowingError"
  @spec new(type :: binary) :: t
  def new(type) when is_binary(type) do
    %__MODULE__{
      message: "You already follow this #{type}",
      code: "already_following",
      status: 409
    }
  end
end
