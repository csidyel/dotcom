defmodule Backstop.Servers do
  use Behaviour

  alias Porcelain.Process

  defcallback run(parent :: pid)
  defcallback command() :: String.t
  defcallback started_regex() :: String.t | Regex.t
  defcallback error_regex() :: String.t | Regex.t

  defmacro __using__([]) do
    quote location: :keep do
      alias Porcelain.Process
      require Logger

      @behaviour unquote(__MODULE__)

      def spawn_server do
        Porcelain.spawn_shell(
          command,
          in: :receive,
          out: {:send, self()},
          err: {:send, self()}
        )
      end

      def loop(proc = %Process{pid: pid}, parent) do
        receive do
          {^pid, :data, :out, data} ->
            if data =~ started_regex do
              send parent, {self(), :started}
            end
            loop(proc, parent)
          {^pid, :data, :err, data} ->
            IO.write data
            if data =~ error_regex do
              send parent, {self(), :error}
            end
            loop(proc, parent)
          {^pid, :result, _result} ->
            send parent, {self(), :finished}
          {^parent, :shutdown} ->
            server_name = __MODULE__
            |> Module.split
            |> List.last

            Logger.info "shutting down " <> server_name
            Process.signal proc, :int
            send parent, {self(), :finished}
        end
      end
    end
  end
end

defmodule Backstop.Servers.Phoenix do
  @moduledoc "Run the Phoenix server."

  use Backstop.Servers

  @lint {Credo.Check.Readability.MaxLineLength, false}
  def command do
    "MIX_ENV=prod PORT=4001 STATIC_HOST=localhost STATIC_PORT=4001 V3_URL=http://localhost:8080 mix do clean, compile, phoenix.server"
  end

  def started_regex do
    "Running Site.Endpoint"
  end

  def error_regex do
    ~r(.)
  end

  def run(parent) do
    proc = spawn_server()
    loop(proc, parent)
  end
end

defmodule Backstop.Servers.Wiremock do
  @moduledoc "Run the Wiremock server."

  use Backstop.Servers

  def command do
    "java -jar #{Application.get_env(:site, :wiremock_path)}"
  end

  def started_regex do
    ~R(port:\s+8080)
  end

  def error_regex do
    "Address already in use"
  end

  def run(parent) do
    File.cd! "apps/site" # apps/site has the Wiremock configuration
    proc = spawn_server()
    File.cd! "../.." # cd back up to the root directory
    loop(proc, parent)
  end
end
