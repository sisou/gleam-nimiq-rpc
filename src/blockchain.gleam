import gleam/dynamic/decode
import gleam/json

import fiber/request

import internal/account.{type Account}
import internal/utils
import nimiq_rpc.{type Client}

// Numbers

/// Returns the block number for the current head.
pub fn get_block_number(client: Client) -> Result(Int, String) {
  let req =
    request.new(method: "getBlockNumber")
    |> request.with_decoder(utils.unwrap_data(decode.int))

  utils.call(client, req)
}

/// Returns the batch number for the current head.
pub fn get_batch_number(client: Client) -> Result(Int, String) {
  let req =
    request.new(method: "getBatchNumber")
    |> request.with_decoder(utils.unwrap_data(decode.int))

  utils.call(client, req)
}

/// Returns the epoch number for the current head.
pub fn get_epoch_number(client: Client) -> Result(Int, String) {
  let req =
    request.new(method: "getEpochNumber")
    |> request.with_decoder(utils.unwrap_data(decode.int))

  utils.call(client, req)
}

// Accounts

/// Tries to fetch the account at the given address.
pub fn get_account_by_address(
  client: Client,
  address: String,
) -> Result(Account, String) {
  let req =
    request.new(method: "getAccountByAddress")
    |> request.with_params(json.preprocessed_array([json.string(address)]))
    |> request.with_decoder(utils.unwrap_data(account.decoder()))

  utils.call(client, req)
}
