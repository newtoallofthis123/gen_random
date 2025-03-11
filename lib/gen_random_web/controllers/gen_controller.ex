defmodule GenRandomWeb.GenController do
  use GenRandomWeb, :controller

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

  def create(conn, params) do
    with %{"schema" => schema, "type" => type, "number" => number} <- params,
         {:ok, response} <- generate_response(schema, type, number) do
      conn
      |> put_status(:ok)
      |> json(%{data: response})
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing required parameters: schema, type, number"})

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
