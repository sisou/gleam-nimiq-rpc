import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}

import fiber/message

pub type Request(return) {
  Request(
    method: String,
    params: Option(Json),
    decoder: decode.Decoder(return),
    id: Option(message.Id),
  )
}

pub fn new(method method: String) -> Request(Dynamic) {
  Request(
    method:,
    params: option.None,
    decoder: decode.dynamic,
    id: option.None,
  )
}

pub fn with_params(request: Request(a), params: Json) -> Request(a) {
  Request(..request, params: option.Some(params))
}

pub fn with_decoder(
  request: Request(a),
  decoder decoder: decode.Decoder(b),
) -> Request(b) {
  Request(
    method: request.method,
    params: request.params,
    decoder:,
    id: request.id,
  )
}
