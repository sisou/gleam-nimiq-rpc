import dispatchers/utils
import nimiq_rpc.{type Client}

import gleam/dynamic

import fiber/request as fiber_request

pub fn get_block_number(
  client: Client,
  timeout timeout: Int,
) -> Result(Int, String) {
  let req =
    fiber_request.new(method: "getBlockNumber")
    |> fiber_request.with_decoder(utils.unwrap_result(dynamic.int))

  utils.call(client, req, timeout)
}

pub fn get_batch_number(
  client: Client,
  timeout timeout: Int,
) -> Result(Int, String) {
  let req =
    fiber_request.new(method: "getBatchNumber")
    |> fiber_request.with_decoder(utils.unwrap_result(dynamic.int))

  utils.call(client, req, timeout)
}

pub fn get_epoch_number(
  client: Client,
  timeout timeout: Int,
) -> Result(Int, String) {
  let req =
    fiber_request.new(method: "getEpochNumber")
    |> fiber_request.with_decoder(utils.unwrap_result(dynamic.int))

  utils.call(client, req, timeout)
}
