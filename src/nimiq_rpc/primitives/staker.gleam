import gleam/dynamic/decode.{type Decoder}
import gleam/option.{type Option}

pub type Staker {
  Staker(
    address: String,
    balance: Int,
    delegation: String,
    inactive_balance: Int,
    inactive_from: Option(Int),
    retired_balance: Int,
  )
}

pub fn decoder() -> Decoder(Staker) {
  use address <- decode.field("address", decode.string)
  use balance <- decode.field("balance", decode.int)
  use delegation <- decode.field("delegation", decode.string)
  use inactive_balance <- decode.field("inactiveBalance", decode.int)
  use inactive_from <- decode.field("inactiveFrom", decode.optional(decode.int))
  use retired_balance <- decode.field("retiredBalance", decode.int)
  decode.success(Staker(
    address:,
    balance:,
    delegation:,
    inactive_balance:,
    inactive_from:,
    retired_balance:,
  ))
}
