defmodule ExLivekit.Utils do
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
