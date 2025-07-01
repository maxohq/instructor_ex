defmodule Instructor.JsonFixer do
  @moduledoc """
  Some models return slightly malformed JSON. This module attempts to fix that.
  """

  def run(content) do
    content
    |> unwrap_json_code_block()
    |> Jason.decode()
  end

  defp unwrap_json_code_block(str) when is_binary(str) do
    regex = ~r/^```json\s*\n(.*?)\n```$/ms

    case Regex.run(regex, str, capture: :all_but_first) do
      [json] -> String.trim(json)
      _ -> str
    end
  end
end
