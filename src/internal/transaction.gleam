import gleam/dynamic/decode.{type Decoder}

pub type Transaction {
  Transaction(
    hash: String,
    timestamp: Int,
    block_number: Int,
    confirmations: Int,
    from: String,
    from_type: Int,
    to: String,
    to_type: Int,
    value: Int,
    fee: Int,
    sender_data: String,
    recipient_data: String,
    flags: Int,
    validity_start_height: Int,
    network_id: Int,
    proof: String,
    execution_result: Bool,
    size: Int,
    related_addresses: List(String),
  )
}

pub fn decoder() -> Decoder(Transaction) {
  use block_number <- decode.field("blockNumber", decode.int)
  use confirmations <- decode.field("confirmations", decode.int)
  use execution_result <- decode.field("executionResult", decode.bool)
  use fee <- decode.field("fee", decode.int)
  use flags <- decode.field("flags", decode.int)
  use from <- decode.field("from", decode.string)
  use from_type <- decode.field("fromType", decode.int)
  use hash <- decode.field("hash", decode.string)
  use network_id <- decode.field("networkId", decode.int)
  use proof <- decode.field("proof", decode.string)
  use recipient_data <- decode.field("recipientData", decode.string)
  use related_addresses <- decode.field(
    "relatedAddresses",
    decode.list(decode.string),
  )
  use sender_data <- decode.field("senderData", decode.string)
  use size <- decode.field("size", decode.int)
  use timestamp <- decode.field("timestamp", decode.int)
  use to <- decode.field("to", decode.string)
  use to_type <- decode.field("toType", decode.int)
  use validity_start_height <- decode.field("validityStartHeight", decode.int)
  use value <- decode.field("value", decode.int)
  decode.success(Transaction(
    block_number:,
    confirmations:,
    execution_result:,
    fee:,
    flags:,
    from:,
    from_type:,
    hash:,
    network_id:,
    proof:,
    recipient_data:,
    related_addresses:,
    sender_data:,
    size:,
    timestamp:,
    to:,
    to_type:,
    validity_start_height:,
    value:,
  ))
}
