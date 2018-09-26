defmodule JSONRPC2.Client.HTTPError do
  @moduledoc false

  defexception [:code, :message]

  def exception(value) when is_map(value) do
    struct(%__MODULE__{}, value)
  end

  def exception(value) when is_atom(value) do
    %__MODULE__{message: JSONRPC2.Misc.reason_to_string(value)}
  end
end

defmodule JSONRPC2.Client.HTTP do
  @moduledoc """
  A JSON RPC HTTP Client.

  ## Examples

      a = 1
      iex> defmodule MyDemo do
      ...>   use JSONRPC2.Client.HTTP
      ...>
      ...>   defcall add(a, b)
      ...>
      ...>   defnotify hello(who)
      ...> end
      iex> MyDemo.add(1, 2)
      {:call, "mydemo_add", [1, 2]}
      iex> MyDemo.hello("John")
      {:notify, "mydemo_hello", ["John"]}
  """

  alias JSONRPC2.{Misc, Request, Response}

  import JSONRPC2.Misc, only: :macros

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name, fn -> Misc.module_name(__CALLER__.module) end)

    quote location: :keep do
      import JSONRPC2.Client.HTTP, only: [defcall: 1, defnotify: 1]

      @name unquote(name)
      @definitions []

      @before_compile JSONRPC2.Client.HTTP
    end
  end

  defmacro __before_compile__(_env) do
    alias JSONRPC2.Client.HTTP

    quote location: :keep do
      defmacro batch(url, do: block) do
        module = __MODULE__
        definitions = @definitions
        {_, _, block} = block

        quote do
          import unquote(module), only: unquote(definitions)

          reqs =
            unquote(block)
            |> List.flatten()
            |> Enum.reject(&is_nil/1)

          HTTP.batch(unquote(url), reqs)
        end
      end
    end
  end

  @doc """
  Defines a JSON RPC call with the given name and body.
  """
  defmacro defcall(call) do
    define(:call, call)
  end

  @doc """
  Defines a JSON RPC notify with the given name and body.
  """
  defmacro defnotify(call) do
    define(:notify, call)
  end

  @doc """
  Makes a synchronous call to the JSON RPC server and waits for its reply.
  """
  def call(url, method, params \\ :undefind) do
    {:call, method, params}
    |> build()
    |> run(url)
  end

  @doc """
  Makes a synchronous notify to the JSON RPC server.
  """
  def notify(url, method, params \\ :undefined) do
    {:notify, method, params}
    |> build()
    |> run(url)
  end

  @doc """
  Makes a batch synchronous call/notify to the JSON RPC server and waits for its reply.
  """
  def batch(url, reqs) when is_nonempty_list(reqs) do
    reqs
    |> Enum.map(&build/1)
    |> run(url)
  end

  defp define(type, {name, meta, args} = call) do
    args = with nil <- args, do: []
    arity = length(args)
    url = Macro.var(:url, nil)
    remote_args = [url | args]
    remote_call = {name, meta, remote_args}
    args = with [{:%{}, _, _} = named_params] <- args, do: named_params

    trailing_bang_call =
      if type == :call do
        trailing_bang_call = {to_trailing_bang(name), meta, remote_args}

        quote do
          def unquote(trailing_bang_call) do
            case unquote(remote_call) do
              {:ok, value} ->
                value

              {:error, reason} ->
                raise JSONRPC2.Client.HTTPError, reason
            end
          end
        end
      else
        quote do
        end
      end

    quote location: :keep do
      @definitions [{unquote(name), unquote(arity)} | @definitions]

      def unquote(call) do
        method = Misc.to_method_name(@name, unquote(name))
        {unquote(type), method, unquote(args)}
      end

      def unquote(remote_call) do
        method = Misc.to_method_name(@name, unquote(name))
        JSONRPC2.Client.HTTP.unquote(type)(unquote(url), method, unquote(args))
      end

      unquote(trailing_bang_call)
    end
  end

  defp run(req, url) do
    unless Misc.all?(req, &Request.valid?/1) do
      raise ArgumentError
    end

    data = Request.encode!(req)

    id =
      if is_list(req) do
        req
        |> Enum.map(&Request.id/1)
        |> Enum.reject(&is_nil/1)
      else
        Request.id(req)
      end

    headers = [
      {"Content-Type", "application/json"}
    ]

    with {:ok, status, _headers, body} <- :hackney.post(url, headers, data, [:with_body]),
         :ok <- Plug.Conn.Status.reason_atom(status) do
      if not Misc.blank?(id) do
        with {:ok, resp} <- Response.decode(body) do
          if Misc.all?(resp, &Response.valid?/1) do
            transform(resp, id)
          else
            {:error, :invalid_response}
          end
        end
      else
        :ok
      end
    else
      reason when is_atom(reason) ->
        {:error, reason}

      reason ->
        reason
    end
  end

  defp transform(resps, ids) when is_nonempty_list(resps) do
    if resps |> Enum.map(& &1.id) |> Enum.sort_by(&String.to_integer/1) == ids do
      resps
      |> Enum.sort_by(& &1.id)
      |> Enum.map(&transform(&1, &1.id))
    else
      {:error, :invalid}
    end
  end

  defp transform(%Response{id: id} = resp, id) do
    if Response.success?(resp) do
      {:ok, resp.result}
    else
      {:error, resp.error}
    end
  end

  defp transform(_resp, _id) do
    {:error, :invalid}
  end

  defp build({:call, method}) do
    build({:call, method, :undefined})
  end

  defp build({:call, method, params}) do
    Request.new(method, params: params, id: Misc.unique_id())
  end

  defp build({:notify, method}) do
    build({:notify, method, :undefined})
  end

  defp build({:notify, method, params}) do
    Request.new(method, params: params)
  end

  defp to_trailing_bang(name) do
    name
    |> Atom.to_string()
    |> Kernel.<>("!")
    |> String.to_atom()
  end
end
