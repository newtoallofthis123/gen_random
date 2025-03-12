# GenRandom

Generate Random Data based on a given schema.

## Usage

GenRandom works best when self hosted, however for a small demo, 
a hosted version is available at [https://gen.noobscience.in](https://gen.noobscience.in).
This version has rate limiting built in for 50 requests that renews every 24 hours.

### Schema

The only endpoint is `POST /generate`.
The body should be a JSON object with the following properties:

* `schema`: The schema to generate data for.
* `type`: The type of data ie `application/json` etc
* `number`: The number of items to generate.

In this above schema, the `schema` property is the only required property.
The defaults are

```json
{
    "schema": "REQUIRED",
    "type": "application/json",
    "number": 4
}
```

The response will be a JSON object with only one property `data` which is an array of objects of the `type` specified.

### Example

```bash
curl -X POST -H "Content-Type: application/json" -d '{"schema": "a person with a name and a age", "type": "application/json", "number": 4}' https://gen.noobscience.in/generate
```

Response:

```json
{
    "data": [
        {
            "name": "John Doe",
            "age": 25
        },
        {
            "name": "Jane Doe",
            "age": 26
        },
        {
            "name": "Bob Smith",
            "age": 27
        },
        {
            "name": "Alice Smith",
            "age": 28
        }
    ]
}
```

### Warning:

The data generated is not guaranteed to be valid against the schema, it is recommended to have a schema validator
built into your application to validate the data.
There are plans on integrating a schema validator into GenRandom in the future for JSON, XML and YAML.

## License

The Code for this project is written using The Phoenix Framework and is licensed under the MIT license.
Check the [LICENSE](LICENSE) file for more information.
