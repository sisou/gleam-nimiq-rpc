import gleam/dynamic/decode.{type Decoder}

pub type Inherent {
  Reward(
    block_number: Int,
    block_time: Int,
    validator_address: String,
    target: String,
    value: Int,
    hash: String,
  )
  Penalize(
    block_number: Int,
    block_time: Int,
    validator_address: String,
    offense_event_block: Int,
  )
  Jail(
    block_number: Int,
    block_time: Int,
    validator_address: String,
    offense_event_block: Int,
  )
}

fn reward_inherent_decoder() -> Decoder(Inherent) {
  use block_number <- decode.field("blockNumber", decode.int)
  use block_time <- decode.field("blockTime", decode.int)
  use validator_address <- decode.field("validatorAddress", decode.string)
  use target <- decode.field("target", decode.string)
  use value <- decode.field("value", decode.int)
  use hash <- decode.field("hash", decode.string)
  decode.success(Reward(
    block_number:,
    block_time:,
    validator_address:,
    target:,
    value:,
    hash:,
  ))
}

fn penalize_inherent_decoder() -> Decoder(Inherent) {
  use block_number <- decode.field("blockNumber", decode.int)
  use block_time <- decode.field("blockTime", decode.int)
  use validator_address <- decode.field("validatorAddress", decode.string)
  use offense_event_block <- decode.field("offenseEventBlock", decode.int)
  decode.success(Penalize(
    block_number:,
    block_time:,
    validator_address:,
    offense_event_block:,
  ))
}

fn jail_inherent_decoder() -> Decoder(Inherent) {
  use block_number <- decode.field("blockNumber", decode.int)
  use block_time <- decode.field("blockTime", decode.int)
  use validator_address <- decode.field("validatorAddress", decode.string)
  use offense_event_block <- decode.field("offenseEventBlock", decode.int)
  decode.success(Jail(
    block_number:,
    block_time:,
    validator_address:,
    offense_event_block:,
  ))
}

pub fn decoder() -> Decoder(Inherent) {
  use typ <- decode.field("type", decode.string)
  case typ {
    "reward" -> reward_inherent_decoder()
    "penalize" -> penalize_inherent_decoder()
    "jail" -> jail_inherent_decoder()
    _ -> decode.failure(Reward(0, 0, "", "", 0, ""), "Unknown inherent type")
  }
}
