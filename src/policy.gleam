import gleam/dynamic/decode
import gleam/json

import fiber/request

import internal/utils
import nimiq_rpc.{type Client}

pub fn get_last_macro_block(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getLastMacroBlock")
  |> request.with_params(json.preprocessed_array([json.int(block_number)]))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

pub fn get_last_election_block(
  client: Client,
  block_number: Int,
) -> Result(Int, String) {
  request.new(method: "getLastElectionBlock")
  |> request.with_params(json.preprocessed_array([json.int(block_number)]))
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}
