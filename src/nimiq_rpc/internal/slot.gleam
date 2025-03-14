import gleam/dynamic/decode.{type Decoder}

pub type Slot {
  Slot(slot_number: Int, validator: String, public_key: String)
}

pub fn slot_decoder() -> Decoder(Slot) {
  use slot_number <- decode.field("slotNumber", decode.int)
  use validator <- decode.field("validator", decode.string)
  use public_key <- decode.field("publicKey", decode.string)
  decode.success(Slot(slot_number:, validator:, public_key:))
}

pub type DisabledSlots {
  DisabledSlots(block_number: Int, disabled: List(Int))
}

pub fn disabled_slots_decoder() -> Decoder(DisabledSlots) {
  use block_number <- decode.field("blockNumber", decode.int)
  use disabled <- decode.field("disabled", decode.list(decode.int))
  decode.success(DisabledSlots(block_number:, disabled:))
}
