import gleam/dynamic/decode
import gleam/json

import fiber/request

import internal/utils
import nimiq_rpc.{type Client}

pub type PolicyConstants {
  PolicyConstants(
    staking_contract_address: String,
    coinbase_address: String,
    transaction_validity_window: Int,
    max_size_micro_body: Int,
    version: Int,
    slots: Int,
    blocks_per_batch: Int,
    batches_per_epoch: Int,
    blocks_per_epoch: Int,
    validator_deposit: Int,
    minimum_stake: Int,
    total_supply: Int,
    block_separation_time: Int,
    jail_epochs: Int,
    genesis_block_number: Int,
  )
}

fn policy_constants_decoder() -> decode.Decoder(PolicyConstants) {
  use staking_contract_address <- decode.field(
    "stakingContractAddress",
    decode.string,
  )
  use coinbase_address <- decode.field("coinbaseAddress", decode.string)
  use transaction_validity_window <- decode.field(
    "transactionValidityWindow",
    decode.int,
  )
  use max_size_micro_body <- decode.field("maxSizeMicroBody", decode.int)
  use version <- decode.field("version", decode.int)
  use slots <- decode.field("slots", decode.int)
  use blocks_per_batch <- decode.field("blocksPerBatch", decode.int)
  use batches_per_epoch <- decode.field("batchesPerEpoch", decode.int)
  use blocks_per_epoch <- decode.field("blocksPerEpoch", decode.int)
  use validator_deposit <- decode.field("validatorDeposit", decode.int)
  use minimum_stake <- decode.field("minimumStake", decode.int)
  use total_supply <- decode.field("totalSupply", decode.int)
  use block_separation_time <- decode.field("blockSeparationTime", decode.int)
  use jail_epochs <- decode.field("jailEpochs", decode.int)
  use genesis_block_number <- decode.field("genesisBlockNumber", decode.int)
  decode.success(PolicyConstants(
    staking_contract_address:,
    coinbase_address:,
    transaction_validity_window:,
    max_size_micro_body:,
    version:,
    slots:,
    blocks_per_batch:,
    batches_per_epoch:,
    blocks_per_epoch:,
    validator_deposit:,
    minimum_stake:,
    total_supply:,
    block_separation_time:,
    jail_epochs:,
    genesis_block_number:,
  ))
}

/// Returns a bundle of policy constants.
pub fn get_policy_constants(client: Client) -> Result(PolicyConstants, String) {
  request.new(method: "getPolicyConstants")
  |> request.with_decoder(utils.unwrap_data(policy_constants_decoder()))
  |> utils.call(client, _)
}

/// Returns the epoch number at a given block number (height).
pub fn get_epoch_at(client: Client, block_number: Int) -> Result(Int, String) {
  request.new(method: "getEpochAt")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the epoch index at a given block number. The epoch index is the number of a block relative
/// to the epoch it is in. For example, the first block of any epoch always has an epoch index of 0.
pub fn get_epoch_index_at(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getEpochIndexAt")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the batch number at a given `block_number` (height).
pub fn get_batch_at(client: Client, block_number: Int) -> Result(Int, String) {
  request.new(method: "getBatchAt")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the batch index at a given block number. The batch index is the number of a block relative
/// to the batch it is in. For example, the first block of any batch always has an batch index of 0.
pub fn get_batch_index_at(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getBatchIndexAt")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the number (height) of the next election macro block after a given block number (height).
pub fn get_election_block_after(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getElectionBlockAfter")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the number block (height) of the preceding election macro block before a given block number (height).
/// If the given block number is an election macro block, it returns the election macro block before it.
pub fn get_election_block_before(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getElectionBlockBefore")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the block number (height) of the last election macro block at a given block number (height).
/// If the given block number is an election macro block, then it returns that block number.
pub fn get_last_election_block(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getLastElectionBlock")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns a boolean expressing if the block at a given block number (height) is an election macro block.
pub fn is_election_block_at(
  client: Client,
  block_number: Int,
) -> Result(Bool, String) {
  request.new(method: "isElectionBlockAt")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.bool))
  |> utils.call(client, _)
}

/// Returns the block number (height) of the next macro block after a given block number (height).
pub fn get_macro_block_after(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getMacroBlockAfter")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the block number (height) of the preceding macro block before a given block number (height).
/// If the given block number is a macro block, it returns the macro block before it.
pub fn get_macro_block_before(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getMacroBlockBefore")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns block the number (height) of the last macro block at a given block number (height).
/// If the given block number is a macro block, then it returns that block number.
pub fn get_last_macro_block(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getLastMacroBlock")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns a boolean expressing if the block at a given block number (height) is a macro block.
pub fn is_macro_block_at(
  client: Client,
  block_number: Int,
) -> Result(Bool, String) {
  request.new(method: "isMacroBlockAt")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.bool))
  |> utils.call(client, _)
}

/// Returns a boolean expressing if the block at a given block number (height) is a micro block.
pub fn is_micro_block_at(
  client: Client,
  block_number: Int,
) -> Result(Bool, String) {
  request.new(method: "isMicroBlockAt")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.bool))
  |> utils.call(client, _)
}

/// Returns the block number of the first block of the given epoch (which is always a micro block).
pub fn get_first_block_of(client: Client, epoch: Int) -> Result(Int, String) {
  request.new(method: "getFirstBlockOf")
  |> request.with_params(json.array([epoch], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the block number of the first block of the given batch (which is always a micro block).
pub fn get_first_block_of_batch(
  client: Client,
  batch: Int,
) -> Result(Int, String) {
  request.new(method: "getFirstBlockOfBatch")
  |> request.with_params(json.array([batch], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the block number of the election macro block of the given epoch (which is always the last block).
pub fn get_election_block_of(client: Client, epoch: Int) -> Result(Int, String) {
  request.new(method: "getElectionBlockOf")
  |> request.with_params(json.array([epoch], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the block number of the macro block (checkpoint or election) of the given batch (which
/// is always the last block).
pub fn get_macro_block_of(client: Client, batch: Int) -> Result(Int, String) {
  request.new(method: "getMacroBlockOf")
  |> request.with_params(json.array([batch], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns a boolean expressing if the batch at a given block number (height) is the first batch
/// of the epoch.
pub fn get_first_batch_of_epoch(
  client: Client,
  block_number: Int,
) -> Result(Bool, String) {
  request.new(method: "getFirstBatchOfEpoch")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.bool))
  |> utils.call(client, _)
}

/// Returns the first block after the reporting window of a given block number has ended.
pub fn get_block_after_reporting_window(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getBlockAfterReportingWindow")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the first block after the jail period of a given block number has ended.
pub fn get_block_after_jail(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getBlockAfterJail")
  |> request.with_params(json.array([block_number], json.int))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the supply at a given time (as Unix time) in Lunas (1 NIM = 100,000 Lunas). It is
/// calculated using the following formula:
/// ```text
/// supply(t) = total_supply - (total_supply - genesis_supply) * supply_decay^t
/// ```
/// Where t is the time in milliseconds since the PoS genesis block and `genesis_supply` is the supply at
/// the genesis of the Nimiq 2.0 chain.
pub fn get_supply_at(
  client: Client,
  genesis_supply: Int,
  genesis_time: Int,
  current_time: Int,
) -> Result(Int, String) {
  request.new(method: "getSupplyAt")
  |> request.with_params(json.array(
    [genesis_supply, genesis_time, current_time],
    json.int,
  ))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}
