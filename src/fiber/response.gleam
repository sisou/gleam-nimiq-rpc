import gleam/json.{type Json}

import fiber/message

pub type Error {
  InvalidParams
  InternalError
  CustomError(message.ErrorData(Json))
}
