import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/pair
import gleam/result

pub type Id {
  IntId(Int)
  StringId(String)
}

pub type ErrorData(dyn) {
  ErrorData(data: Option(dyn), code: Int, message: String)
  /// This breaks specification, but some implementations do it anyways. It's
  /// better to handle it than to cause decode errors, especially since such
  /// errors are likely not recoverable like structured ones would be.
  ErrorString(String)
}

pub type Request(dyn) {
  Request(params: Option(dyn), method: String, id: Id)
  Notification(params: Option(dyn), method: String)
}

pub type Response(dyn) {
  SuccessResponse(result: dyn, id: Id)
  ErrorResponse(error: ErrorData(dyn), id: Id)
}

pub type Message(dyn) {
  RequestMessage(Request(dyn))
  ResponseMessage(Response(dyn))
  ErrorMessage(ErrorData(dyn))
  BatchRequestMessage(List(Request(dyn)))
  BatchResponseMessage(List(Response(dyn)))
}

fn id_decoder() -> decode.Decoder(Id) {
  decode.one_of(decode.int |> decode.map(IntId), [
    decode.string |> decode.map(StringId),
  ])
  |> decode.collapse_errors("Id")
}

fn error_data_decoder() -> decode.Decoder(ErrorData(Dynamic)) {
  decode.one_of(decode.string |> decode.map(ErrorString), [
    {
      use data <- decode.optional_field(
        "data",
        option.None,
        decode.optional(decode.dynamic),
      )
      use code <- decode.field("code", decode.int)
      use message <- decode.field("message", decode.string)
      decode.success(ErrorData(data, code, message))
    },
  ])
  |> decode.collapse_errors("ErrorData")
}

fn request_decoder() -> decode.Decoder(Request(Dynamic)) {
  decode.one_of(
    {
      use params <- decode.optional_field(
        "params",
        option.None,
        decode.optional(decode.dynamic),
      )
      use method <- decode.field("method", decode.string)
      use id <- decode.field("id", id_decoder())
      decode.success(Request(params, method, id))
    },
    [
      {
        use params <- decode.optional_field(
          "params",
          option.None,
          decode.optional(decode.dynamic),
        )
        use method <- decode.field("method", decode.string)
        decode.success(Notification(params, method))
      },
    ],
  )
  |> decode.collapse_errors("Request")
}

fn response_decoder() -> decode.Decoder(Response(Dynamic)) {
  decode.one_of(
    {
      use result <- decode.field("result", decode.dynamic)
      use id <- decode.field("id", id_decoder())
      decode.success(SuccessResponse(result, id))
    },
    [
      {
        use error <- decode.field("error", error_data_decoder())
        use id <- decode.field("id", id_decoder())
        decode.success(ErrorResponse(error, id))
      },
    ],
  )
  |> decode.collapse_errors("Response")
}

fn error_decoder() -> decode.Decoder(ErrorData(Dynamic)) {
  use error <- decode.field("error", error_data_decoder())
  decode.success(error)
}

fn message_decoder() -> decode.Decoder(Message(Dynamic)) {
  decode.one_of(response_decoder() |> decode.map(ResponseMessage), [
    request_decoder() |> decode.map(RequestMessage),
    error_decoder() |> decode.map(ErrorMessage),
    decode.list(request_decoder()) |> decode.map(BatchRequestMessage),
    decode.list(response_decoder()) |> decode.map(BatchResponseMessage),
  ])
  |> decode.collapse_errors("Message")
}

pub fn decode(text: String) -> Result(Message(Dynamic), json.DecodeError) {
  json.parse(text, message_decoder())
}

pub fn from_json(text: String) -> Result(Message(Dynamic), json.DecodeError) {
  decode(text)
}

fn encode_id(id: Id) {
  case id {
    IntId(i) -> json.int(i)
    StringId(s) -> json.string(s)
  }
}

fn encode_error_data(error: ErrorData(Json)) {
  case error {
    ErrorData(data, code, message) ->
      json.object(
        result.values([
          #("code", json.int(code)) |> Ok,
          #("message", json.string(message)) |> Ok,
          data
            |> option.map(pair.new("data", _))
            |> option.to_result(Nil),
        ]),
      )
    ErrorString(s) -> json.string(s)
  }
}

fn encode_request(request: Request(Json)) {
  case request {
    Notification(params, method) ->
      json.object(
        result.values([
          #("jsonrpc", json.string("2.0")) |> Ok,
          #("method", json.string(method)) |> Ok,
          option.map(params, pair.new("params", _)) |> option.to_result(Nil),
        ]),
      )
    Request(params, method, id) ->
      json.object(
        result.values([
          #("jsonrpc", json.string("2.0")) |> Ok,
          #("id", encode_id(id)) |> Ok,
          #("method", json.string(method)) |> Ok,
          params
            |> option.map(pair.new("params", _))
            |> option.unwrap(#("params", json.preprocessed_array([])))
            |> Ok(),
        ]),
      )
  }
}

fn encode_response(response: Response(Json)) {
  case response {
    ErrorResponse(error, id) ->
      json.object([
        #("jsonrpc", json.string("2.0")),
        #("id", encode_id(id)),
        #("error", encode_error_data(error)),
      ])
    SuccessResponse(result, id) ->
      json.object([
        #("jsonrpc", json.string("2.0")),
        #("id", encode_id(id)),
        #("result", result),
      ])
  }
}

fn encode_error(error: ErrorData(Json)) {
  json.object([
    #("jsonrpc", json.string("2.0")),
    #("id", json.null()),
    #("error", encode_error_data(error)),
  ])
}

pub fn encode(message: Message(Json)) -> Json {
  case message {
    BatchRequestMessage(batch) -> batch |> json.array(encode_request)
    BatchResponseMessage(batch) -> batch |> json.array(encode_response)
    ErrorMessage(error) -> encode_error(error)
    RequestMessage(request) -> encode_request(request)
    ResponseMessage(response) -> encode_response(response)
  }
}

pub fn to_json(message: Message(Json)) -> Json {
  encode(message)
}
