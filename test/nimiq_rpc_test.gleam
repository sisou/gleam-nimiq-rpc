import gleam/list
import gleam/option.{None, Some}
import gleeunit
import nimiq_rpc
import nimiq_rpc/blockchain
import nimiq_rpc/consensus
import nimiq_rpc/policy

pub fn main() {
  gleeunit.main()
}

pub fn nimiq_rpc_test() {
  let client = nimiq_rpc.client("https://rpc.nimiqwatch.com")

  assert client |> consensus.is_consensus_established() == Ok(True)

  let assert Ok(policy) = client |> policy.get_policy_constants()

  let assert Ok(block_number) = client |> blockchain.get_block_number()
  assert block_number > policy.genesis_block_number

  let assert Ok(transactions) =
    client
    |> blockchain.get_transactions_by_address(
      "NQ07 0000 0000 0000 0000 0000 0000 0000 0000",
      Some(1),
      None,
    )
  assert transactions |> list.length() == 1
}
