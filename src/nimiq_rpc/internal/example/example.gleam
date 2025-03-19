import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result

import dot_env
import dot_env/env

import nimiq_rpc/primitives/account
import nimiq_rpc/primitives/block.{Macro, Micro}

import nimiq_rpc.{type Client}
import nimiq_rpc/blockchain
import nimiq_rpc/policy

fn get_heights(client: Client) -> #(Int, Int, Int) {
  let assert Ok(height) = client |> blockchain.get_block_number()
  io.debug(height)

  let assert Ok(batch) = client |> blockchain.get_batch_number()
  io.debug(batch)

  // let assert Ok(epoch) = client |> blockchain.get_epoch_number()
  // io.debug(epoch)

  #(height, batch, 0)
}

fn get_accounts(client: Client) {
  let assert Ok(basic_account) =
    client
    |> blockchain.get_account_by_address(
      "NQ07 0000 0000 0000 0000 0000 0000 0000 0000",
    )
  let _ = case basic_account {
    account.Basic(..) -> {
      io.debug(basic_account)
    }
    _ -> panic as "Expected Basic account"
  }

  let assert Ok(vesting_contract) =
    client
    |> blockchain.get_account_by_address(
      "NQ37 JJN3 P9QA EP99 JFPP HVHH CNL9 QG4R 7L7D",
    )
  let _ = case vesting_contract {
    account.Vesting(..) -> {
      io.debug(vesting_contract)
    }
    _ -> panic as "Expected Vesting account"
  }

  let assert Ok(htlc_contract) =
    client
    |> blockchain.get_account_by_address(
      "NQ04 0F84 VMAQ EN3H YDYP 4B9R XSRB 6XD2 CPSM",
    )
  let _ = case htlc_contract {
    account.HTLC(..) -> {
      io.debug(htlc_contract)
    }
    _ -> panic as "Expected HTLC account"
  }

  let assert Ok(staking_contract) =
    client
    |> blockchain.get_account_by_address(
      "NQ77 0000 0000 0000 0000 0000 0000 0000 0001",
    )
  let _ = case staking_contract {
    account.Staking(..) -> {
      io.debug(staking_contract)
    }
    _ -> panic as "Expected Staking account"
  }
}

fn get_transactions(client: Client) {
  let assert Ok(hashes) =
    client
    |> blockchain.get_transaction_hashes_by_address(
      "NQ07 0000 0000 0000 0000 0000 0000 0000 0000",
      Some(1),
      None,
    )
  io.debug(hashes)

  let assert Ok(transaction) =
    client
    |> blockchain.get_transaction_by_hash(
      hashes |> list.first() |> result.unwrap(""),
    )
  io.debug(transaction)

  let assert Ok(transactions) =
    client
    |> blockchain.get_transactions_by_block_number(transaction.block_number)
  io.debug(transactions |> list.length())

  let assert Ok(transactions) =
    client
    |> blockchain.get_transactions_by_address(transaction.to, Some(1), None)
  io.debug(transactions |> list.length())
}

fn get_slots(client: Client, height: Int) {
  let assert Ok(slot) = client |> blockchain.get_slot_at(height, None)
  io.debug(slot)

  let assert Ok(slots) = client |> blockchain.get_current_penalized_slots()
  io.debug(slots.disabled |> list.length())

  let assert Ok(slots) = client |> blockchain.get_previous_penalized_slots()
  io.debug(slots.disabled |> list.length())
}

fn get_validator(client: Client) {
  let assert Ok(validator) =
    client
    |> blockchain.get_validator_by_address(
      "NQ57 UQJL 5A3H N45M 1FHS 2454 C7L5 BTE6 KEU1",
    )
  io.debug(validator)
}

fn get_staker(client: Client) {
  let assert Ok(staker) =
    client
    |> blockchain.get_staker_by_address(
      "NQ96 A1CY 9EXQ P2AR F12X 883K L14S QV44 3HUH",
    )
  io.debug(staker)
}

fn get_blocks(client: Client) {
  let assert Ok(head) = client |> blockchain.get_latest_block(Some(False))
  io.debug(head)
  let is_election_block = case head {
    Micro(number: head_height, ..) -> {
      let assert Ok(macro_height) =
        client |> policy.get_last_macro_block(head_height)
      let assert Ok(macro_block) =
        client |> blockchain.get_block_by_number(macro_height, Some(False))
      io.debug(macro_block)

      case macro_block {
        Macro(is_election_block:, ..) -> is_election_block
        _ -> False
      }
    }
    Macro(number: head_height, is_election_block:, ..) -> {
      let assert Ok(micro_block) =
        client |> blockchain.get_block_by_number(head_height - 1, Some(False))
      io.debug(micro_block)

      is_election_block
    }
  }

  case is_election_block {
    True -> {
      Nil
    }
    False -> {
      let assert Ok(election_head) =
        client |> policy.get_last_election_block(head.number)
      let assert Ok(election_block) =
        client |> blockchain.get_block_by_number(election_head, Some(False))
      io.debug(election_block)
      Nil
    }
  }
}

fn get_inherents(client: Client, batch: Int) {
  let assert Ok(inherents) =
    client |> blockchain.get_inherents_by_batch_number(batch - 1)
  io.debug(inherents |> list.length())
}

fn get_policy(client: Client, height: Int) {
  let assert Ok(constants) = client |> policy.get_policy_constants()
  io.debug(constants)

  let assert Ok(election_height) =
    client |> policy.get_election_block_before(height)
  let assert Ok(True) = client |> policy.is_election_block_at(election_height)
  let assert Ok(False) =
    client |> policy.is_election_block_at(election_height - 1)
  let assert Ok(True) = client |> policy.is_macro_block_at(election_height)
  let assert Ok(False) = client |> policy.is_macro_block_at(election_height - 1)
  let assert Ok(False) = client |> policy.is_micro_block_at(election_height)
  let assert Ok(True) = client |> policy.is_micro_block_at(election_height - 1)
}

pub fn main() {
  dot_env.new_with_path("src/nimiq_rpc/internal/example/.env") |> dot_env.load()

  let assert Ok(url) = env.get_string("RPC_URL")
  let assert Ok(username) = env.get_string("RPC_USERNAME")
  let assert Ok(password) = env.get_string("RPC_PASSWORD")

  let client = nimiq_rpc.client_with_auth(url, username, password)

  let #(height, batch, _epoch) = get_heights(client)
  get_accounts(client)
  get_transactions(client)
  get_slots(client, height)
  get_validator(client)
  get_staker(client)
  get_blocks(client)
  get_inherents(client, batch)
  get_policy(client, height)
}
