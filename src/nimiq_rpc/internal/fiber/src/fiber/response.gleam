import gleam/json.{type Json}

import nimiq_rpc/internal/fiber/src/fiber/message

pub type Error {
  InvalidParams
  InternalError
  CustomError(message.ErrorData(Json))
}
