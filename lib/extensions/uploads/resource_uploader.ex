# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Uploads.ResourceUploader do
  use MoodleNet.Uploads.Definition

  def transform(_file), do: :skip
end
