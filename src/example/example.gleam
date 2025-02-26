import gleam/io

import dotenv_gleam
import envoy

import blockchain
import nimiq_rpc.{type Client}

fn get_heights(client: Client) {
  let assert Ok(height) = client |> blockchain.get_block_number(timeout: 1000)
  io.debug(height)
  // let assert Ok(batch) = client |> blockchain.get_batch_number(timeout: 1000)
  // io.debug(batch)

  // let assert Ok(epoch) = client |> blockchain.get_epoch_number(timeout: 1000)
  // io.debug(epoch)
}

pub fn main() {
  dotenv_gleam.config_with("src/example/.env")

  let assert Ok(url) = envoy.get("RPC_URL")
  let assert Ok(username) = envoy.get("RPC_USERNAME")
  let assert Ok(password) = envoy.get("RPC_PASSWORD")

  let client = nimiq_rpc.client_with_auth(url, username, password)

  get_heights(client)
}
