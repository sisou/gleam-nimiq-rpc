import gleam/dynamic/decode.{type Decoder}

import nimiq_rpc/internal/hash

pub type Account {
  Basic(address: String, balance: Int)
  Vesting(
    address: String,
    balance: Int,
    owner: String,
    start_time: Int,
    step_amount: Int,
    time_step: Int,
    total_amount: Int,
  )
  HTLC(
    address: String,
    balance: Int,
    hash_count: Int,
    hash_root: hash.Hash,
    recipient: String,
    sender: String,
    timeout: Int,
    total_amount: Int,
  )
  Staking(address: String, balance: Int)
}

fn basic_decoder() -> Decoder(Account) {
  use address <- decode.field("address", decode.string)
  use balance <- decode.field("balance", decode.int)
  decode.success(Basic(address:, balance:))
}

fn vesting_decoder() -> Decoder(Account) {
  use address <- decode.field("address", decode.string)
  use balance <- decode.field("balance", decode.int)
  use owner <- decode.field("owner", decode.string)
  use start_time <- decode.field("vestingStartTime", decode.int)
  use step_amount <- decode.field("vestingStepAmount", decode.int)
  use time_step <- decode.field("vestingTimeStep", decode.int)
  use total_amount <- decode.field("vestingTotalAmount", decode.int)
  decode.success(Vesting(
    address:,
    balance:,
    owner:,
    start_time:,
    step_amount:,
    time_step:,
    total_amount:,
  ))
}

fn htlc_decoder() -> Decoder(Account) {
  use address <- decode.field("address", decode.string)
  use balance <- decode.field("balance", decode.int)
  use hash_count <- decode.field("hashCount", decode.int)
  use hash_root <- decode.field("hashRoot", hash.decoder())
  use recipient <- decode.field("recipient", decode.string)
  use sender <- decode.field("sender", decode.string)
  use timeout <- decode.field("timeout", decode.int)
  use total_amount <- decode.field("totalAmount", decode.int)
  decode.success(HTLC(
    address:,
    balance:,
    hash_count:,
    hash_root:,
    recipient:,
    sender:,
    timeout:,
    total_amount:,
  ))
}

fn staking_decoder() -> Decoder(Account) {
  use address <- decode.field("address", decode.string)
  use balance <- decode.field("balance", decode.int)
  decode.success(Staking(address:, balance:))
}

pub fn decoder() -> Decoder(Account) {
  use typ <- decode.field("type", decode.string)
  case typ {
    "basic" -> basic_decoder()
    "vesting" -> vesting_decoder()
    "htlc" -> htlc_decoder()
    "staking" -> staking_decoder()
    _ -> decode.failure(Basic("", 0), "Account")
  }
}
