# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Uploads.Storage do
  @type file_source :: Belt.file_source()
  @type file_info :: %{info: %Belt.FileInfo{}, media_type: binary, metadata: map}
  @type file_id :: binary

  @spec store(file :: file_source()) :: {:ok, file_info()} | {:error, term}
  def store(file, opts \\ []) do
    opts = [overwrite: true] ++ opts

    with {:ok, file} <- allow_extension(file, opts),
         {:ok, file_info} <- upload_provider() |> Belt.store(file, opts),
         {:ok, metadata} <- get_metadata(file) do
      media_type = format_to_media_type(metadata.format)

      {:ok,
       %{id: file_info.identifier, info: file_info, media_type: media_type, metadata: metadata}}
    end
  end

  @spec remote_url(file_id()) :: {:ok, binary} | {:error, term}
  def remote_url(file_id) do
    upload_provider() |> Belt.get_url(file_id)
  end

  @spec delete(file_id()) :: :ok | {:error, term}
  def delete(file_id) do
    upload_provider() |> Belt.delete(file_id)
  end

  @scope :test
  @spec delete_all() :: :ok | {:error, term}
  def delete_all do
    upload_provider() |> Belt.delete_all()
  end

  defp upload_provider do
    provider_config = Application.fetch_env!(:moodle_net, __MODULE__) |> Keyword.fetch!(:provider)

    {:ok, provider} =
      case provider_config do
        provider when is_atom(provider) -> provider.new()
        [provider, config] when is_atom(provider) -> apply(provider, :new, config)
      end

    provider
  end

  defp get_metadata(%{path: path}) do
    with {:ok, binary} <- File.read(path) do
      case FormatParser.parse(binary) do
        {:error, "Unknown"} -> {:error, :unsupported_format}
        info when is_map(info) -> {:ok, Map.from_struct(info)}
        other -> other
      end
    end
  end

  defp allow_extension(path, opts) when is_binary(path) do
    allow_extension(%{path: path, filename: Path.basename(path)}, opts)
  end

  defp allow_extension(%{path: path} = file, opts) do
    case Keyword.get(opts, :extensions, :all) do
      :all ->
        {:ok, file}

      allowed ->
        if MoodleNet.File.has_extension?(path, allowed) do
          {:ok, file}
        else
          {:error, :extension_denied}
        end
    end
  end

  defp format_to_media_type(format) do
    # HACK: format_parser.ex uses a weird format, returning what seems to mostly
    # be an atom of the file type. E.g. `test-image.png` => `:png`.
    maybe_ext = to_string(format)
    MIME.type(maybe_ext)
  end
end