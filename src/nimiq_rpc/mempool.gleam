import gleam/dynamic/decode.{type Decoder}
import gleam/json

import nimiq_rpc/internal/fiber/src/fiber/request

import nimiq_rpc.{type Client}
import nimiq_rpc/internal/transaction.{type Transaction}
import nimiq_rpc/internal/utils

pub type HashOrTx {
  Hash(String)
  Tx(Transaction)
}

fn hash_or_tx_decoder() -> Decoder(HashOrTx) {
  decode.one_of(decode.string |> decode.map(Hash), [
    transaction.decoder() |> decode.map(Tx),
  ])
  |> decode.collapse_errors("HashOrTx")
}

pub type MempoolInfo {
  MempoolInfo(
    bucket_0: Int,
    bucket_1: Int,
    bucket_2: Int,
    bucket_5: Int,
    bucket_10: Int,
    bucket_20: Int,
    bucket_50: Int,
    bucket_100: Int,
    bucket_200: Int,
    bucket_500: Int,
    bucket_1000: Int,
    bucket_2000: Int,
    bucket_5000: Int,
    bucket_10000: Int,
    total: Int,
    buckets: List(Int),
  )
}

fn mempool_info_decoder() -> Decoder(MempoolInfo) {
  use bucket_0 <- decode.optional_field("0", 0, decode.int)
  use bucket_1 <- decode.optional_field("1", 0, decode.int)
  use bucket_2 <- decode.optional_field("2", 0, decode.int)
  use bucket_5 <- decode.optional_field("5", 0, decode.int)
  use bucket_10 <- decode.optional_field("10", 0, decode.int)
  use bucket_20 <- decode.optional_field("20", 0, decode.int)
  use bucket_50 <- decode.optional_field("50", 0, decode.int)
  use bucket_100 <- decode.optional_field("100", 0, decode.int)
  use bucket_200 <- decode.optional_field("200", 0, decode.int)
  use bucket_500 <- decode.optional_field("500", 0, decode.int)
  use bucket_1000 <- decode.optional_field("1000", 0, decode.int)
  use bucket_2000 <- decode.optional_field("2000", 0, decode.int)
  use bucket_5000 <- decode.optional_field("5000", 0, decode.int)
  use bucket_10000 <- decode.optional_field("10000", 0, decode.int)
  use total <- decode.field("total", decode.int)
  use buckets <- decode.field("buckets", decode.list(decode.int))
  decode.success(MempoolInfo(
    bucket_0:,
    bucket_1:,
    bucket_2:,
    bucket_5:,
    bucket_10:,
    bucket_20:,
    bucket_50:,
    bucket_100:,
    bucket_200:,
    bucket_500:,
    bucket_1000:,
    bucket_2000:,
    bucket_5000:,
    bucket_10000:,
    total:,
    buckets:,
  ))
}

/// Pushes a raw transaction with a default priority assigned into the mempool and broadcast it to the network.
pub fn push_transaction(
  client: Client,
  raw_tx: String,
) -> Result(String, String) {
  request.new(method: "pushTransaction")
  |> request.with_params(json.array([raw_tx], json.string))
  |> request.with_decoder(utils.unwrap_data(decode.string))
  |> utils.call(client, _)
}

/// Pushes a raw transaction with a high priority assigned into the mempool and broadcast it to the network.
pub fn push_high_priority_transaction(
  client: Client,
  raw_tx: String,
) -> Result(String, String) {
  request.new(method: "pushHighPriorityTransaction")
  |> request.with_params(json.array([raw_tx, "high"], json.string))
  |> request.with_decoder(utils.unwrap_data(decode.string))
  |> utils.call(client, _)
}

/// Obtains the list of transactions that are currently in the mempool.
pub fn mempool_content(
  client: Client,
  include_transactions: Bool,
) -> Result(List(HashOrTx), String) {
  request.new(method: "mempoolContent")
  |> request.with_params(json.array([include_transactions], json.bool))
  |> request.with_decoder(utils.unwrap_data(decode.list(hash_or_tx_decoder())))
  |> utils.call(client, _)
}

/// Obtains the mempool content in fee per byte buckets.
pub fn mempool(client: Client) -> Result(MempoolInfo, String) {
  request.new(method: "mempool")
  |> request.with_decoder(utils.unwrap_data(mempool_info_decoder()))
  |> utils.call(client, _)
}

/// Obtains the minimum fee per byte as per mempool configuration.
pub fn get_min_fee_per_byte(client: Client) -> Result(Int, String) {
  request.new(method: "getMinFeePerByte")
  |> request.with_decoder(utils.unwrap_data(decode.int))
  |> utils.call(client, _)
}

/// Tries to obtain the given transaction (using its hash) from the mempool.
pub fn get_transaction_from_mempool(
  client: Client,
  hash: String,
) -> Result(Transaction, String) {
  request.new(method: "getTransactionFromMempool")
  |> request.with_params(json.array([hash], json.string))
  |> request.with_decoder(utils.unwrap_data(transaction.decoder()))
  |> utils.call(client, _)
}
