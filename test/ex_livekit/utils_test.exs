defmodule ExLivekit.UtilsTest do
  use ExUnit.Case, async: true

  describe "snake_to_lower_camel/1" do
    test "converts a snake case string to a lower camel case string" do
      assert ExLivekit.Utils.snake_to_lower_camel("snake_case") == "snakeCase"
      assert ExLivekit.Utils.snake_to_lower_camel(:snake_case) == "snakeCase"
    end
  end

  describe "camel_to_snake/1" do
    test "converts a camel case string to a snake case string" do
      assert ExLivekit.Utils.camel_to_snake("camelCase") == "camel_case"
      assert ExLivekit.Utils.camel_to_snake("CamelCase") == "camel_case"
    end
  end
end
