import gleam/io

import dotenv_gleam
import envoy

import blockchain
import internal/account
import nimiq_rpc.{type Client}

fn get_heights(client: Client) {
  let assert Ok(height) = client |> blockchain.get_block_number()
  io.debug(height)
  // let assert Ok(batch) = client |> blockchain.get_batch_number(timeout: 1000)
  // io.debug(batch)

  // let assert Ok(epoch) = client |> blockchain.get_epoch_number(timeout: 1000)
  // io.debug(epoch)
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
  // let assert Ok(vesting_contract) =
  //   client
  //   |> blockchain.get_account_by_address(
  //     "NQ37 JJN3 P9QA EP99 JFPP HVHH CNL9 QG4R 7L7D",
  //     timeout: 1000,
  //   )
  // let _ = case vesting_contract {
  //   account.Vesting(..) -> {
  //     io.debug(vesting_contract)
  //   }
  //   _ -> panic as "Expected Vesting account"
  // }

  // let assert Ok(htlc_contract) =
  //   client
  //   |> blockchain.get_account_by_address(
  //     "NQ04 0F84 VMAQ EN3H YDYP 4B9R XSRB 6XD2 CPSM",
  //     timeout: 1000,
  //   )
  // let _ = case htlc_contract {
  //   account.HTLC(..) -> {
  //     io.debug(htlc_contract)
  //   }
  //   _ -> panic as "Expected HTLC account"
  // }

  // let assert Ok(staking_contract) =
  //   client
  //   |> blockchain.get_account_by_address(
  //     "NQ77 0000 0000 0000 0000 0000 0000 0000 0001",
  //     timeout: 1000,
  //   )
  // let _ = case staking_contract {
  //   account.Staking(..) -> {
  //     io.debug(staking_contract)
  //   }
  //   _ -> panic as "Expected Staking account"
  // }
}

pub fn main() {
  dotenv_gleam.config_with("src/example/.env")

  let assert Ok(url) = envoy.get("RPC_URL")
  let assert Ok(username) = envoy.get("RPC_USERNAME")
  let assert Ok(password) = envoy.get("RPC_PASSWORD")

  let client = nimiq_rpc.client_with_auth(url, username, password)

  get_heights(client)
  get_accounts(client)
}
