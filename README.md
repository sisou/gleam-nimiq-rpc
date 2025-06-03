# Nimiq JSON-RPC Client Library for Gleam

[![Package Version](https://img.shields.io/hexpm/v/nimiq_rpc)](https://hex.pm/packages/nimiq_rpc)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_rpc/)

## Installation

```sh
gleam add nimiq_rpc
```

## Usage

First, create a client instance:

```gleam
import nimiq_rpc

pub fn main() {
  let client = nimiq_rpc.client("http://localhost:8648")

  // To add authentication information, use this function instead:
  let client = nimiq_rpc.client_with_auth(
    "http://localhost:8648",
    "username",
    "password",
  )
}
```

Each RPC method has its own typed method in this library. The methods are ordered by dispatcher, just like they are in the Rust source code (but your editor's auto-import should help you resolve each method name you want to use). The name of each method is the `snake_case` version of the `camelCase` method name.

```gleam
import nimiq_rpc/consensus
import nimiq_rpc/blockchain

pub fn main() {
  // ...

  let assert Ok(has_consensus) = client |> consensus.is_consensus_established()
  echo has_consensus // True or False

  let assert Ok(number) = client |> blockchain.get_block_number()
  echo number // For example 13424115
}
```

Further documentation of the individual methods can be found at <https://hexdocs.pm/nimiq_rpc>.
