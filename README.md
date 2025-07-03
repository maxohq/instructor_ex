# instructor_ex

_Structured, Ecto outputs with OpenAI (and OSS LLMs)_

---

[![Instructor version](https://img.shields.io/hexpm/v/instructor.svg)](https://hex.pm/packages/instructor)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/instructor/)
[![Hex Downloads](https://img.shields.io/hexpm/dt/instructor)](https://hex.pm/packages/instructor)
[![GitHub stars](https://img.shields.io/github/stars/thmsmlr/instructor_ex.svg)](https://github.com/thmsmlr/instructor_ex/stargazers)
[![Twitter Follow](https://img.shields.io/twitter/follow/thmsmlr?style=social)](https://twitter.com/thmsmlr)
[![Discord](https://img.shields.io/discord/1192334452110659664?label=discord)](https://discord.gg/bD9YE9JArw)

<!-- Docs -->

Check out our [Quickstart Guide](https://hexdocs.pm/instructor/quickstart.html) to get up and running with Instructor in minutes.

Instructor provides structured prompting for LLMs. It is a spiritual port of the great [Instructor Python Library](https://github.com/jxnl/instructor) by [@jxnlco](https://twitter.com/jxnlco).

Instructor allows you to get structured output out of an LLM using Ecto.  
You don't have to define any JSON schemas.
You can just use Ecto as you've always used it.  
And since it's just ecto, you can provide change set validations that you can use to ensure that what you're getting back from the LLM is not only properly structured, but semantically correct.

To learn more about the philosophy behind Instructor and its motivations, check out this Elixir Denver Meetup talk:

<div style="text-align: center">

[![Instructor: Structured prompting for LLMs](assets/youtube-thumbnail.png)](https://www.youtube.com/watch?v=RABXu7zqnT0)

</div>

While Instructor is designed to be used with OpenAI, it also supports every major AI lab and open source LLM inference server:

- OpenAI
- Anthropic
- Groq
- Ollama
- Gemini
- vLLM
- llama.cpp

At its simplest, usage is pretty straightforward: 

1. Create an ecto schema, with a `@llm_doc` string that explains the schema definition to the LLM. 
2. Define a `validate_changeset/1` function on the schema, and use the `use Instructor` macro in order for Instructor to know about it.
2. Make a call to `Instructor.chat_completion/1` with an instruction for the LLM to execute.

You can use the `max_retries` parameter to automatically, iteratively go back and forth with the LLM to try fixing validation errorswhen they occur.

```elixir
Mix.install([:instructor])

defmodule SpamPrediction do
  use Ecto.Schema
  use Validator

  @llm_doc """
  ## Field Descriptions:
  - class: Whether or not the email is spam.
  - reason: A short, less than 10 word rationalization for the classification.
  - score: A confidence score between 0.0 and 1.0 for the classification.
  """
  @primary_key false
  embedded_schema do
    field(:class, Ecto.Enum, values: [:spam, :not_spam])
    field(:reason, :string)
    field(:score, :float)
  end

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_number(:score,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 1.0
    )
  end
end

is_spam? = fn text ->
  Instructor.chat_completion(
    model: "gpt-4o-mini",
    response_model: SpamPrediction,
    max_retries: 3,
    messages: [
      %{
        role: "user",
        content: """
        Your purpose is to classify customer support emails as either spam or not.
        This is for a clothing retail business.
        They sell all types of clothing.

        Classify the following email: 

        <email>
          #{text}
        </email>
        """
      }
    ]
  )
end

is_spam?.("Hello I am a Nigerian prince and I would like to send you money")

# => {:ok, %SpamPrediction{class: :spam, reason: "Nigerian prince email scam", score: 0.98}}
```

<!-- Docs -->

## HTTP Communication Hooks

Instructor provides a flexible way to customize HTTP requests and responses globally using hooks. This is useful for logging, instrumentation, modifying requests, or handling responses in a consistent way across your application.

### Registering Global Hooks

You can register global request and response hooks using the `Instructor.HttpClient` module. Hooks are functions that receive and return the request or response. All HTTP requests made by Instructor will pass through these hooks.

#### Example: Logging Requests and Responses

```elixir
defmodule MyLogger do
  def log_request(request, options) do
    IO.inspect({request, options}, label: "Outgoing HTTP Request")
    request
  end

  def log_response(response, options) do
    IO.inspect({response, options}, label: "Incoming HTTP Response")
    response
  end
end

# Register hooks at application startup (e.g., in your Application start/2)
Instructor.HttpClient.register_request_hook(&MyLogger.log_request/2)
Instructor.HttpClient.register_response_hook(&MyLogger.log_response/2)


### You can also set global hooks in your `config/config.exs`:
config :instructor, Instructor.HttpClient,
  request_hooks: [&MyLogger.log_request/2],
  response_hooks: [&MyLogger.log_response/2]
```

### How Hooks Work
- **Request hooks** are called before the HTTP request is sent. You can modify the request or just observe it. Hooks receive both the request and the options.
- **Response hooks** are called after the HTTP response is received. You can modify or log the response. Hooks receive both the response and the options.
- Multiple hooks can be registered; they are called in the order they were registered.

### Use Cases
- Logging all HTTP traffic
- Adding custom headers or authentication
- Instrumentation and metrics
- Response validation or transformation

### API Reference
- `Instructor.HttpClient.register_request_hook((request, options -> request))`
- `Instructor.HttpClient.register_response_hook((response, options -> response))`

See the [source code](lib/instructor/http_client.ex) and tests for more advanced usage.


## Installation

In your mix.exs,

```elixir
def deps do
  [
    {:instructor, "~> 0.1.0"}
  ]
end
```
