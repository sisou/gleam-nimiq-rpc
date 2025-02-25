# Nimiq JSON-RPC Client for Gleam

[![Package Version](https://img.shields.io/hexpm/v/nimiq_rpc)](https://hex.pm/packages/nimiq_rpc)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_rpc/)

## Installation

```sh
gleam add nimiq_rpc
```

## Usage

```gleam
import gleam/io

import nimiq_rpc
import nimiq_rpc/dispatchers/blockchain

pub fn main() {
  let client = nimiq_rpc.client("http://localhost:8648")

  let height = client |> blockchain.get_block_number(timeout: 1000)
  io.debug(height)
}
```

<!-- Further documentation can be found at <https://hexdocs.pm/nimiq_rpc>. -->
