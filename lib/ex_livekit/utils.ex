defmodule ExLivekit.Utils do
  @moduledoc false

  @spec to_http_url(binary()) :: binary()
  def to_http_url("ws://" <> rest), do: "http://" <> rest
  def to_http_url("wss://" <> rest), do: "https://" <> rest
  def to_http_url("http://" <> rest), do: "http://" <> rest
  def to_http_url("https://" <> rest), do: "https://" <> rest
  def to_http_url(url), do: "http://" <> url

  @spec snake_to_lower_camel(binary() | atom()) :: binary()
  def snake_to_lower_camel(data) when is_atom(data) do
    snake_to_lower_camel(Atom.to_string(data))
  end

  def snake_to_lower_camel(data) when is_binary(data) do
    <<h, t::binary>> = Macro.camelize(data)
    String.downcase(<<h>>) <> t
  end

  @spec camel_to_snake(binary()) :: binary()
  def camel_to_snake(string) do
    Macro.underscore(string)
  end
end
