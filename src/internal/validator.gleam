import gleam/dynamic/decode.{type Decoder}
import gleam/option.{type Option}

pub type Validator {
  Validator(
    address: String,
    reward_address: String,
    balance: Int,
    voting_key: String,
    signing_key: String,
    signal_data: Option(String),
    inactivity_flag: Option(Int),
    jailed_from: Option(Int),
    retired: Bool,
    num_stakers: Int,
  )
}

pub fn decoder() -> Decoder(Validator) {
  use address <- decode.field("address", decode.string)
  use balance <- decode.field("balance", decode.int)
  use inactivity_flag <- decode.field(
    "inactivityFlag",
    decode.optional(decode.int),
  )
  use jailed_from <- decode.field("jailedFrom", decode.optional(decode.int))
  use num_stakers <- decode.field("numStakers", decode.int)
  use retired <- decode.field("retired", decode.bool)
  use reward_address <- decode.field("rewardAddress", decode.string)
  use signal_data <- decode.field("signalData", decode.optional(decode.string))
  use signing_key <- decode.field("signingKey", decode.string)
  use voting_key <- decode.field("votingKey", decode.string)
  decode.success(Validator(
    address:,
    balance:,
    inactivity_flag:,
    jailed_from:,
    num_stakers:,
    retired:,
    reward_address:,
    signal_data:,
    signing_key:,
    voting_key:,
  ))
}
