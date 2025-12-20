defmodule ExLivekit.Utils do
  @spec to_http_url(binary()) :: binary()
  def to_http_url(url) do
    case URI.parse(url).scheme do
      "ws" -> String.replace(url, "ws", "http")
      "wss" -> String.replace(url, "wss", "https")
      "http" -> url
      "https" -> url
      _other -> "http://" <> url
    end
  end

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
