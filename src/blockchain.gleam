import gleam/dynamic/decode
import gleam/json

import fiber/request

import internal/account.{type Account}
import internal/utils
import nimiq_rpc.{type Client}

pub fn get_block_number(
  client: Client,
  timeout timeout: Int,
) -> Result(Int, String) {
  let req =
    request.new(method: "getBlockNumber")
    |> request.with_decoder(utils.unwrap_data(decode.int))

  utils.call(client, req, timeout)
}

pub fn get_batch_number(
  client: Client,
  timeout timeout: Int,
) -> Result(Int, String) {
  let req =
    request.new(method: "getBatchNumber")
    |> request.with_decoder(utils.unwrap_data(decode.int))

  utils.call(client, req, timeout)
}

pub fn get_epoch_number(
  client: Client,
  timeout timeout: Int,
) -> Result(Int, String) {
  let req =
    request.new(method: "getEpochNumber")
    |> request.with_decoder(utils.unwrap_data(decode.int))

  utils.call(client, req, timeout)
}

pub fn get_account_by_address(
  client: Client,
  address: String,
  timeout timeout: Int,
) -> Result(Account, String) {
  let req =
    request.new(method: "getAccountByAddress")
    |> request.with_params(json.preprocessed_array([json.string(address)]))
    |> request.with_decoder(utils.unwrap_data(account.decoder()))

  utils.call(client, req, timeout)
}
