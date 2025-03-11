defmodule GenRandomWeb.GenController do
  alias GenRandom.Repo
  use GenRandomWeb, :controller

  @doc """
  The system prompt for the Google Gemini API.
  """
  def system_prompt() do
    prompt = "You are a random data generator.
    Your job is to generate n number of random data entries based on the provided schema and type.
    The content of data that you have to generate should be based on the description of the schema.
    For example:
    Schema: Person = {
    \"name\": \"Name of the person\",
    \"age\": \"Age of the person\",
    \"email\": \"Email of the person\",
    \"address\": \"Address of the person\"
    }
    Type: application/json
    Number of entries: 2
    Response:
    {\"persons\": [{
      \"name\": \"John Doe\",
      \"age\": 30,
      \"email\": \"john.doe@example.com\",
      \"address\": \"123 Main St, Anytown, USA\"
    }, {
      \"name\": \"Jane Doe\",
      \"age\": 25,
      \"email\": \"jane.doe@example.com\",
      \"address\": \"456 Elm St, Anytown, USA\"
    }]}
    So for json, the response should be {\"persons\": []} for xml, the response should be <persons></persons>

    Example
    Schema:
    <Person>
    <Name>The name of the person</Name>
    <Age>The age of the person</Age>
    <Email>The email of the person</Email>
    <Address>The address of the person</Address>
    </Name>

    Type: application/xml
    Number: 2

    <Persons>
      <Person>
        <Name>John Doe</Name>
        <Age>30</Age>
        <Email>john.doe@example.com</Email>
        <Address>123 Main St, Anytown, USA</Address>
      </Person>
      <Person>
        <Name>Jane Doe</Name>
        <Age>25</Age>
        <Email>jane.doe@example.com</Email>
        <Address>456 Elm St, Anytown, USA</Address>
      </Person>
    </Persons>
    "
    prompt
  end

  @doc """
  Sends a request to the Google Gemini API.
  """
  def send_req(body, api_key) do
    url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}"

    # Increased timeouts to 30 seconds
    options = [timeout: 30_000, recv_timeout: 30_000]

    payload =
      Jason.encode!(%{
        "system_instruction" => %{
          "parts" => %{"text" => system_prompt()}
        },
        "contents" => %{
          "parts" => %{"text" => body}
        }
      })

    response = HTTPoison.post(url, payload, [], options)
    response
  end

  @doc """
  Parses the response from the Google Gemini API.
  """
  def parse_response(body) do
    parsed = Jason.decode(body)

    case parsed do
      {:ok, parsed_body} ->
        if not Map.has_key?(parsed_body, "candidates") do
          {:error, "Invalid response"}
        else
          res = Enum.at(Enum.at(parsed_body["candidates"], 0)["content"]["parts"], 0)["text"]
          res = String.replace(res, ~r/```[\w\s]*\n|\n```/, "")
          {:ok, res}
        end

      {:error, _} ->
        {:error, "Invalid Response from LLM"}
    end
  end

  @doc """
  Generates a random response based on the given schema, type, and number.
  Calls the Google Gemini API to generate the response and is hence
  blocking.
  """
  def generate_response(schema, type, number) do
    api_key = System.get_env("GOOGLE_API_KEY")
    query = "Generate #{number} random #{type} entries based on the following schema: #{schema}"
    response = send_req(query, api_key)

    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_response(body)

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, status_code}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def generate_response(schema) do
    generate_response(schema, "application/json", 5)
  end

  def generate_response(schema, number) do
    generate_response(schema, "application/json", number)
  end

  @doc """
  Sanitizes the output by removing all newlines and tabs.
  """
  def sanitise_output(output) do
    output |> String.replace(~r/\n|\t/, "")
  end

  def create(conn, params) do
    with params when is_map(params) <- params do
      # Add to requests table
      ip_string = :inet.ntoa(conn.remote_ip) |> to_string()

      # Check if the ip_string has a request that is less than a day old
      requests =
        Repo.query(
          "SELECT COUNT(*) FROM requests WHERE addr = $1 AND inserted_at >= NOW() - INTERVAL '1 day'",
          [
            ip_string
          ]
        )

      case requests do
        {:ok, %Postgrex.Result{rows: [[count]]}} when count > 50 ->
          conn
          |> put_status(:too_many_requests)
          |> json(%{error: "Too many requests! You have run out of your free 50 requests/day."})

        _ ->
          :ok
      end

      case Repo.insert(%GenRandom.Request{addr: ip_string, endpoint: conn.request_path}) do
        {:ok, _} -> :ok
        {:error, _} -> :error
      end

      case params do
        %{"schema" => schema} when map_size(params) == 1 ->
          case generate_response(schema) do
            {:ok, response} ->
              conn
              |> put_status(:ok)
              |> json(%{data: sanitise_output(response)})

            error ->
              handle_error(conn, error)
          end

        %{"schema" => schema, "number" => number} when map_size(params) == 2 ->
          case generate_response(schema, number) do
            {:ok, response} ->
              conn
              |> put_status(:ok)
              |> json(%{data: sanitise_output(response)})

            error ->
              handle_error(conn, error)
          end

        %{"schema" => schema, "type" => type, "number" => number} ->
          case generate_response(schema, type, number) do
            {:ok, response} ->
              conn
              |> put_status(:ok)
              |> json(%{data: sanitise_output(response)})

            error ->
              handle_error(conn, error)
          end

        _ ->
          conn
          |> put_status(:bad_request)
          |> json(%{
            error:
              "Invalid parameters. Provide either 'schema' only or 'schema', 'type', and 'number'"
          })
      end
    end
  end

  defp handle_error(conn, error) do
    case error do
      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing required parameters"})

      {:error, status_code} when is_integer(status_code) ->
        conn
        |> put_status(status_code)
        |> json(%{error: "API request failed"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Internal server error", reason: reason})
    end
  end

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{message: "Generate endpoint, POST only"})
  end
end
