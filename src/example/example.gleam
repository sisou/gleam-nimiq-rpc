import dispatchers/blockchain
import gleam/io
import nimiq_rpc

pub fn main() {
  let client =
    nimiq_rpc.client_with_auth("https://rpc.pos.v2.test.nimiqwatch.com", "", "")

  let height = client |> blockchain.get_block_number(timeout: 1000)
  io.debug(height)

  let batch = client |> blockchain.get_batch_number(timeout: 1000)
  io.debug(batch)

  let epoch = client |> blockchain.get_epoch_number(timeout: 1000)
  io.debug(epoch)
}
