import gleam/dynamic/decode
import gleam/json

import nimiq_rpc/internal/fiber/src/fiber/request

import nimiq_rpc.{type Client}
import nimiq_rpc/internal/utils
import nimiq_rpc/primitives/transaction.{type Transaction}

/// Returns a boolean specifying if we have established consensus with the network.
pub fn is_consensus_established(client: Client) -> Result(Bool, String) {
  request.new(method: "isConsensusEstablished")
  |> request.with_decoder(utils.unwrap_data(decode.bool))
  |> utils.call(client, _)
}

/// Given a serialized transaction, it will return the corresponding transaction struct.
pub fn get_raw_transaction_info(
  client: Client,
  raw_tx raw_tx: String,
) -> Result(Transaction, String) {
  request.new(method: "getRawTransactionInfo")
  |> request.with_params(json.array([raw_tx], json.string))
  |> request.with_decoder(utils.unwrap_data(transaction.decoder()))
  |> utils.call(client, _)
}

/// Given a serialized transaction, it will return the corresponding transaction struct.
pub fn send_raw_transaction(
  client: Client,
  raw_tx raw_tx: String,
) -> Result(String, String) {
  request.new(method: "sendRawTransaction")
  |> request.with_params(json.array([raw_tx], json.string))
  |> request.with_decoder(utils.unwrap_data(decode.string))
  |> utils.call(client, _)
}
