import gleam/dynamic.{type Dynamic}
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

import fiber
import fiber/backend
import fiber/message
import fiber/request as fiber_request

fn readable_error(
  err: fiber.RequestError(Result(Dynamic, message.ErrorData(Dynamic))),
) -> String {
  case err {
    fiber.ReturnedError(message.ErrorData(data, code, message)) -> {
      let data = case data {
        Some(data) ->
          case data |> dynamic.string() {
            Ok(data) -> Some(data)
            Error(_) -> None
          }
        None -> None
      }

      message
      <> data |> option.map(fn(data) { ": " <> data }) |> option.unwrap("")
      <> " (code: "
      <> code |> int.to_string()
      <> ")"
    }
    fiber.ReturnedError(message.ErrorString(message)) -> message
    fiber.DecodeError(errors) -> {
      list.map(errors, fn(err) {
        "Decoding error: expected "
        <> err.expected
        <> " but found "
        <> err.found
        <> " at "
        <> err.path |> list.first() |> result.unwrap("root")
      })
      |> string.join(", ")
    }
    fiber.CallError(process.CalleeDown(_)) -> "Client actor process down"
    fiber.CallError(process.CallTimeout) -> "Timeout"
  }
}

pub fn call(
  fiber: backend.Fiber,
  req: fiber_request.Request(a),
  timeout timeout: Int,
) -> Result(a, String) {
  fiber.call(fiber, req, timeout) |> result.map_error(readable_error)
}

pub fn unwrap_result(
  decoder: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
) -> fn(Dynamic) -> Result(a, List(dynamic.DecodeError)) {
  dynamic.field("data", decoder)
}
