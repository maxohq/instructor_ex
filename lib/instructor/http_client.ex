defmodule Instructor.HttpClient do
  @moduledoc """
  HTTP client for Instructor.
  """

  @doc """
  Get a resource from the given URL.
  """
  def get(request, options \\ []) do
    Req.get(request, options)
  end

  def post(request, options \\ []) do
    Req.post(request, options)
  end

  def post!(request, options \\ []) do
    Req.post!(request, options)
  end
end
