import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

import fiber/request

import internal/account.{type Account}
import internal/block.{type Block}
import internal/inherent.{type Inherent}
import internal/slot.{type DisabledSlots, type Slot}
import internal/staker.{type Staker}
import internal/transaction.{type Transaction}
import internal/utils
import internal/validator.{type Validator}
import nimiq_rpc.{type Client}

// Numbers

/// Returns the block number for the current head.
pub fn get_block_number(client: Client) -> Result(Int, String) {
  request.new(method: "getBlockNumber")
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the batch number for the current head.
pub fn get_batch_number(client: Client) -> Result(Int, String) {
  request.new(method: "getBatchNumber")
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns the epoch number for the current head.
pub fn get_epoch_number(client: Client) -> Result(Int, String) {
  request.new(method: "getEpochNumber")
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

// Blocks

/// Tries to fetch a block given its hash. It has an option to include the transactions in the
/// block, which defaults to false.
pub fn get_block_by_hash(
  client: Client,
  hash: String,
  include_body: Option(Bool),
) -> Result(Block, String) {
  request.new(method: "getBlockByHash")
  |> request.with_params(
    json.preprocessed_array([
      json.string(hash),
      include_body |> option.map(json.bool) |> option.unwrap(json.null()),
    ]),
  )
  |> request.with_decoder(utils.unwrap_data(block.decoder()))
  |> utils.call(client, _)
}

/// Tries to fetch a block given its number. It has an option to include the transactions in the
/// block, which defaults to false. Note that this function will only fetch blocks that are part
/// of the main chain.
pub fn get_block_by_number(
  client: Client,
  number: Int,
  include_body: Option(Bool),
) -> Result(Block, String) {
  request.new(method: "getBlockByNumber")
  |> request.with_params(
    json.preprocessed_array([
      json.int(number),
      include_body |> option.map(json.bool) |> option.unwrap(json.null()),
    ]),
  )
  |> request.with_decoder(utils.unwrap_data(block.decoder()))
  |> utils.call(client, _)
}

/// Returns the block at the head of the main chain. It has an option to include the
/// transactions in the block, which defaults to false.
pub fn get_latest_block(
  client: Client,
  include_body: Option(Bool),
) -> Result(Block, String) {
  request.new(method: "getLatestBlock")
  |> request.with_params(
    json.preprocessed_array([
      include_body |> option.map(json.bool) |> option.unwrap(json.null()),
    ]),
  )
  |> request.with_decoder(utils.unwrap_data(block.decoder()))
  |> utils.call(client, _)
}

// Slots

/// Returns information about the proposer slot at the given block height and offset. The
/// offset is optional, it will default to getting the offset for the existing block
/// at the given height.
///
/// We only have this information available for the last 2 batches at most.
pub fn get_slot_at(
  client: Client,
  block_number: Int,
  offset_opt: Option(Int),
) -> Result(Slot, String) {
  request.new(method: "getSlotAt")
  |> request.with_params(
    json.preprocessed_array([
      json.int(block_number),
      offset_opt |> option.map(json.int) |> option.unwrap(json.null()),
    ]),
  )
  |> request.with_decoder(utils.unwrap_data(slot.slot_decoder()))
  |> utils.call(client, _)
}

/// Returns information about the currently penalized slots. This includes slots that lost rewards
/// and that were disabled.
pub fn get_current_penalized_slots(
  client: Client,
) -> Result(DisabledSlots, String) {
  request.new(method: "getCurrentPenalizedSlots")
  |> request.with_decoder(utils.unwrap_data(slot.disabled_slots_decoder()))
  |> utils.call(client, _)
}

/// Returns information about the penalized slots of the previous batch. This includes slots that
/// lost rewards and that were disabled.
pub fn get_previous_penalized_slots(
  client: Client,
) -> Result(DisabledSlots, String) {
  request.new(method: "getPreviousPenalizedSlots")
  |> request.with_decoder(utils.unwrap_data(slot.disabled_slots_decoder()))
  |> utils.call(client, _)
}

// Receipts

/// Returns the hashes for the latest transactions for a given address. All the transactions
/// where the given address is listed as a recipient or as a sender are considered. Reward
/// transactions are also returned. It has an option to specify the maximum number of hashes to
/// fetch, it defaults to 500. It has also an option to retrieve transactions before a given
/// transaction hash (exclusive). If this hash is not found or does not belong to this address, it will return an empty list.
/// The transaction hashes are returned in descending order, meaning the latest transaction is the first.
pub fn get_transaction_hashes_by_address(
  client: Client,
  address: String,
  max: Option(Int),
  start_at: Option(String),
) -> Result(List(String), String) {
  request.new(method: "getTransactionHashesByAddress")
  |> request.with_params(
    json.preprocessed_array([
      json.string(address),
      max |> option.map(json.int) |> option.unwrap(json.null()),
      start_at |> option.map(json.string) |> option.unwrap(json.null()),
    ]),
  )
  |> request.with_decoder(utils.unwrap_data(decode.list(decode.string)))
  |> utils.call(client, _)
}

// Transactions

/// Tries to fetch a transaction (including reward transactions) given its hash.
pub fn get_transaction_by_hash(
  client: Client,
  hash: String,
) -> Result(Transaction, String) {
  request.new(method: "getTransactionByHash")
  |> request.with_params(json.preprocessed_array([json.string(hash)]))
  |> request.with_decoder(utils.unwrap_data(transaction.decoder()))
  |> utils.call(client, _)
}

/// Returns all the transactions (including reward transactions) for the given block number. Note
/// that this only considers blocks in the main chain.
pub fn get_transactions_by_block_number(
  client: Client,
  number: Int,
) -> Result(List(Transaction), String) {
  request.new(method: "getTransactionsByBlockNumber")
  |> request.with_params(json.preprocessed_array([json.int(number)]))
  |> request.with_decoder(utils.unwrap_data(decode.list(transaction.decoder())))
  |> utils.call(client, _)
}

/// Returns all the transactions (including reward transactions) for the given batch number. Note
/// that this only considers blocks in the main chain.
pub fn get_transactions_by_batch_number(
  client: Client,
  number: Int,
) -> Result(List(Transaction), String) {
  request.new(method: "getTransactionsByBatchNumber")
  |> request.with_params(json.preprocessed_array([json.int(number)]))
  |> request.with_decoder(utils.unwrap_data(decode.list(transaction.decoder())))
  |> utils.call(client, _)
}

/// Returns the latest transactions for a given address. All the transactions
/// where the given address is listed as a recipient or as a sender are considered. Reward
/// transactions are also returned. It has an option to specify the maximum number of transactions
/// to fetch, it defaults to 500. It has also an option to retrieve transactions before a given
/// transaction hash (exclusive). If this hash is not found or does not belong to this address, it will return an empty list.
/// The transactions are returned in descending order, meaning the latest transaction is the first.
pub fn get_transactions_by_address(
  client: Client,
  address: String,
  max: Option(Int),
  start_at: Option(String),
) -> Result(List(Transaction), String) {
  request.new(method: "getTransactionsByAddress")
  |> request.with_params(
    json.preprocessed_array([
      json.string(address),
      max |> option.map(json.int) |> option.unwrap(json.null()),
      start_at |> option.map(json.string) |> option.unwrap(json.null()),
    ]),
  )
  |> request.with_decoder(utils.unwrap_data(decode.list(transaction.decoder())))
  |> utils.call(client, _)
}

// Inherents

/// Returns all the inherents (including reward inherents) for the given block number. Note
/// that this only considers blocks in the main chain.
pub fn get_inherents_by_block_number(
  client: Client,
  number: Int,
) -> Result(List(Inherent), String) {
  request.new(method: "getInherentsByBlockNumber")
  |> request.with_params(json.preprocessed_array([json.int(number)]))
  |> request.with_decoder(utils.unwrap_data(decode.list(inherent.decoder())))
  |> utils.call(client, _)
}

/// Returns all the inherents (including reward inherents) for the given batch number. Note
/// that this only considers blocks in the main chain.
pub fn get_inherents_by_batch_number(
  client: Client,
  number: Int,
) -> Result(List(Inherent), String) {
  request.new(method: "getInherentsByBatchNumber")
  |> request.with_params(json.preprocessed_array([json.int(number)]))
  |> request.with_decoder(utils.unwrap_data(decode.list(inherent.decoder())))
  |> utils.call(client, _)
}

// Accounts

/// Tries to fetch the account at the given address.
pub fn get_account_by_address(
  client: Client,
  address: String,
) -> Result(Account, String) {
  request.new(method: "getAccountByAddress")
  |> request.with_params(json.preprocessed_array([json.string(address)]))
  |> request.with_decoder(utils.unwrap_data(account.decoder()))
  |> utils.call(client, _)
}

/// Fetches all accounts in the accounts tree.
///
/// **IMPORTANT:** This operation iterates over all accounts in the accounts tree
/// and thus is extremely computationally expensive.
pub fn dangerously_get_accounts(client: Client) -> Result(List(Account), String) {
  request.new(method: "getAccounts")
  |> request.with_decoder(utils.unwrap_data(decode.list(account.decoder())))
  |> utils.call(client, _)
}

// Validators

/// Tries to fetch a validator information given its address.
pub fn get_validator_by_address(
  client: Client,
  address: String,
) -> Result(Validator, String) {
  request.new(method: "getValidatorByAddress")
  |> request.with_params(json.preprocessed_array([json.string(address)]))
  |> request.with_decoder(utils.unwrap_data(validator.decoder()))
  |> utils.call(client, _)
}

/// Returns a collection of the currently active validator's addresses and balances.
pub fn get_active_validators(client: Client) -> Result(List(Validator), String) {
  request.new(method: "getActiveValidators")
  |> request.with_decoder(utils.unwrap_data(decode.list(validator.decoder())))
  |> utils.call(client, _)
}

/// Fetches all validators in the staking contract.
///
/// **IMPORTANT:** This operation iterates over all validators in the staking contract
/// and thus is extremely computationally expensive.
pub fn dangerously_get_validators(
  client: Client,
) -> Result(List(Validator), String) {
  request.new(method: "getValidators")
  |> request.with_decoder(utils.unwrap_data(decode.list(validator.decoder())))
  |> utils.call(client, _)
}

// Stakers

/// Fetches all stakers for a given validator.
///
/// **IMPORTANT:** This operation iterates over all stakers of the staking contract
/// and thus is extremely computationally expensive.
pub fn dangerously_get_stakers_by_validator_address(
  client: Client,
  address: String,
) -> Result(List(Staker), String) {
  request.new(method: "getStakersByValidatorAddress")
  |> request.with_params(json.preprocessed_array([json.string(address)]))
  |> request.with_decoder(utils.unwrap_data(decode.list(staker.decoder())))
  |> utils.call(client, _)
}

/// Tries to fetch a staker information given its address.
pub fn get_staker_by_address(
  client: Client,
  address: String,
) -> Result(Staker, String) {
  request.new(method: "getStakerByAddress")
  |> request.with_params(json.preprocessed_array([json.string(address)]))
  |> request.with_decoder(utils.unwrap_data(staker.decoder()))
  |> utils.call(client, _)
}
