defmodule Instructor.HttpClient do
  @moduledoc """
  HTTP client for Instructor, with support for global request and response hooks.
  """

  @app :instructor
  @config_key __MODULE__

  @doc """
  Register a global request hook. The hook should be a function (request -> request).
  """
  def register_request_hook(hook_fun) when is_function(hook_fun, 1) do
    hooks = get_request_hooks() ++ [hook_fun]
    put_request_hooks(hooks)
    :ok
  end

  @doc """
  Register a global response hook. The hook should be a function (response -> response).
  """
  def register_response_hook(hook_fun) when is_function(hook_fun, 1) do
    hooks = get_response_hooks() ++ [hook_fun]
    put_response_hooks(hooks)
    :ok
  end

  @doc """
  Get a resource from the given URL, applying global hooks.
  """
  def get(request, options \\ []) do
    request = apply_request_hooks(request)
    response = Req.get(request, options)
    apply_response_hooks(response)
  end

  def post(request, options \\ []) do
    request = apply_request_hooks(request)
    response = Req.post(request, options)
    apply_response_hooks(response)
  end

  def post!(request, options \\ []) do
    request = apply_request_hooks(request)
    response = Req.post!(request, options)
    apply_response_hooks(response)
  end

  # Internal helpers
  defp get_request_hooks do
    Application.get_env(@app, @config_key, [])[:request_hooks] || []
  end

  defp get_response_hooks do
    Application.get_env(@app, @config_key, [])[:response_hooks] || []
  end

  defp put_request_hooks(hooks) do
    config = Application.get_env(@app, @config_key, [])
    Application.put_env(@app, @config_key, Keyword.put(config, :request_hooks, hooks))
  end

  defp put_response_hooks(hooks) do
    config = Application.get_env(@app, @config_key, [])
    Application.put_env(@app, @config_key, Keyword.put(config, :response_hooks, hooks))
  end

  defp apply_request_hooks(request) do
    Enum.reduce(get_request_hooks(), request, fn hook, acc -> hook.(acc) end)
  end

  defp apply_response_hooks(response) do
    Enum.reduce(get_response_hooks(), response, fn hook, acc -> hook.(acc) end)
  end
end
