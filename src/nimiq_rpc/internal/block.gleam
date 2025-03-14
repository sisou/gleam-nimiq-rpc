import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/option.{type Option, None}

pub type MacroSignatureInner {
  MacroSignatureInner(signature: String)
}

fn macro_signature_inner_decoder() -> Decoder(MacroSignatureInner) {
  use signature <- decode.field("signature", decode.string)
  decode.success(MacroSignatureInner(signature:))
}

pub type MacroSignature {
  MacroSignature(signature: MacroSignatureInner, signers: List(Int))
}

fn macro_signature_decoder() -> Decoder(MacroSignature) {
  use signature <- decode.field("signature", macro_signature_inner_decoder())
  use signers <- decode.field("signers", decode.list(decode.int))
  decode.success(MacroSignature(signature:, signers:))
}

pub type Justification {
  MicroJustification(micro: String)
  MacroJustification(round: Int, sig: MacroSignature)
}

fn micro_justification_decoder() -> Decoder(Justification) {
  use micro <- decode.field("micro", decode.string)
  decode.success(MicroJustification(micro:))
}

fn macro_justification_decoder() -> Decoder(Justification) {
  use round <- decode.field("round", decode.int)
  use sig <- decode.field("sig", macro_signature_decoder())
  decode.success(MacroJustification(round:, sig:))
}

fn justification_decoder() -> Decoder(Justification) {
  decode.one_of(micro_justification_decoder(), [macro_justification_decoder()])
}

pub type Producer {
  MicroProducer(public_key: String, slot_number: Int, validator: String)
}

fn producer_decoder() -> Decoder(Producer) {
  use public_key <- decode.field("publicKey", decode.string)
  use slot_number <- decode.field("slotNumber", decode.int)
  use validator <- decode.field("validator", decode.string)
  decode.success(MicroProducer(public_key:, slot_number:, validator:))
}

pub type Slots {
  Slots(
    first_slot_number: Int,
    num_slots: Int,
    validator: String,
    public_key: String,
  )
}

fn slots_decoder() -> Decoder(Slots) {
  use first_slot_number <- decode.field("firstSlotNumber", decode.int)
  use num_slots <- decode.field("numSlots", decode.int)
  use validator <- decode.field("validator", decode.string)
  use public_key <- decode.field("publicKey", decode.string)
  decode.success(Slots(first_slot_number:, num_slots:, validator:, public_key:))
}

pub type Block {
  Micro(
    hash: String,
    size: Int,
    batch: Int,
    epoch: Int,
    // TODO: Network enum?
    network: String,
    version: Int,
    number: Int,
    timestamp: Int,
    parent_hash: String,
    seed: String,
    extra_data: String,
    state_hash: String,
    body_hash: String,
    history_hash: String,
    transactions: Option(List(Dynamic)),
    // Micro-specific fields
    producer: Producer,
    equivocation_proofs: Option(List(Dynamic)),
    justification: Option(Justification),
  )
  Macro(
    hash: String,
    size: Int,
    batch: Int,
    epoch: Int,
    // TODO: Network enum?
    network: String,
    version: Int,
    number: Int,
    timestamp: Int,
    parent_hash: String,
    seed: String,
    extra_data: String,
    state_hash: String,
    body_hash: String,
    history_hash: String,
    transactions: Option(List(Dynamic)),
    // Macro-specific fields
    is_election_block: Bool,
    justification: Justification,
    next_batch_initial_punished_set: List(Int),
    parent_election_hash: String,
    interlink: Option(List(String)),
    slots: Option(List(Slots)),
  )
}

fn micro_block_decoder() -> Decoder(Block) {
  use hash <- decode.field("hash", decode.string)
  use size <- decode.field("size", decode.int)
  use batch <- decode.field("batch", decode.int)
  use epoch <- decode.field("epoch", decode.int)
  use network <- decode.field("network", decode.string)
  use version <- decode.field("version", decode.int)
  use number <- decode.field("number", decode.int)
  use timestamp <- decode.field("timestamp", decode.int)
  use parent_hash <- decode.field("parentHash", decode.string)
  use seed <- decode.field("seed", decode.string)
  use extra_data <- decode.field("extraData", decode.string)
  use state_hash <- decode.field("stateHash", decode.string)
  use body_hash <- decode.field("bodyHash", decode.string)
  use history_hash <- decode.field("historyHash", decode.string)
  use transactions <- decode.optional_field(
    "transactions",
    None,
    decode.optional(decode.list(decode.dynamic)),
  )

  use producer <- decode.field("producer", producer_decoder())
  use equivocation_proofs <- decode.optional_field(
    "equivocationProofs",
    None,
    decode.optional(decode.list(decode.dynamic)),
  )
  use justification <- decode.optional_field(
    "justification",
    None,
    decode.optional(justification_decoder()),
  )
  decode.success(Micro(
    hash:,
    size:,
    batch:,
    epoch:,
    network:,
    version:,
    number:,
    timestamp:,
    parent_hash:,
    seed:,
    extra_data:,
    state_hash:,
    body_hash:,
    history_hash:,
    transactions:,
    producer:,
    equivocation_proofs:,
    justification:,
  ))
}

fn macro_block_decoder() -> Decoder(Block) {
  use hash <- decode.field("hash", decode.string)
  use size <- decode.field("size", decode.int)
  use batch <- decode.field("batch", decode.int)
  use epoch <- decode.field("epoch", decode.int)
  use network <- decode.field("network", decode.string)
  use version <- decode.field("version", decode.int)
  use number <- decode.field("number", decode.int)
  use timestamp <- decode.field("timestamp", decode.int)
  use parent_hash <- decode.field("parentHash", decode.string)
  use seed <- decode.field("seed", decode.string)
  use extra_data <- decode.field("extraData", decode.string)
  use state_hash <- decode.field("stateHash", decode.string)
  use body_hash <- decode.field("bodyHash", decode.string)
  use history_hash <- decode.field("historyHash", decode.string)
  use transactions <- decode.optional_field(
    "transactions",
    None,
    decode.optional(decode.list(decode.dynamic)),
  )

  use is_election_block <- decode.field("isElectionBlock", decode.bool)
  use justification <- decode.field("justification", justification_decoder())
  use next_batch_initial_punished_set <- decode.field(
    "nextBatchInitialPunishedSet",
    decode.list(decode.int),
  )
  use parent_election_hash <- decode.field("parentElectionHash", decode.string)
  use interlink <- decode.optional_field(
    "interlink",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use slots <- decode.optional_field(
    "slots",
    None,
    decode.optional(decode.list(slots_decoder())),
  )
  decode.success(Macro(
    hash:,
    size:,
    batch:,
    epoch:,
    network:,
    version:,
    number:,
    timestamp:,
    parent_hash:,
    seed:,
    extra_data:,
    state_hash:,
    body_hash:,
    history_hash:,
    transactions:,
    is_election_block:,
    justification:,
    next_batch_initial_punished_set:,
    parent_election_hash:,
    interlink:,
    slots:,
  ))
}

pub fn decoder() -> Decoder(Block) {
  use typ <- decode.field("type", decode.string)
  case typ {
    "micro" -> micro_block_decoder()
    "macro" -> macro_block_decoder()
    _ ->
      decode.failure(
        Micro(
          hash: "",
          size: 0,
          batch: 0,
          epoch: 0,
          network: "",
          version: 0,
          number: 0,
          timestamp: 0,
          parent_hash: "",
          seed: "",
          extra_data: "",
          state_hash: "",
          body_hash: "",
          history_hash: "",
          transactions: None,
          producer: MicroProducer(public_key: "", slot_number: 0, validator: ""),
          equivocation_proofs: None,
          justification: None,
        ),
        "Invalid block type",
      )
  }
}
