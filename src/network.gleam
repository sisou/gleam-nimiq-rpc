import gleam/dynamic/decode

import fiber/request

import internal/utils
import nimiq_rpc.{type Client}

/// Returns the peer ID for our local peer.
pub fn get_peer_id(client: Client) -> Result(String, String) {
  request.new(method: "getPeerId")
  |> request.with_decoder(utils.unwrap_data(decode.string))
  |> utils.call(client, _)
}

/// Returns the number of peers.
pub fn get_peer_count(client: Client) -> Result(Int, String) {
  request.new(method: "getPeerCount")
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Returns a list with the IDs of all our peers.
pub fn get_peer_list(client: Client) -> Result(List(String), String) {
  request.new(method: "getPeerList")
  |> request.with_decoder(utils.unwrap_data(decode.list(decode.string)))
  |> utils.call(client, _)
}
