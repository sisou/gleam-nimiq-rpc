import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import youid/uuid

import fiber/backend
import fiber/message
import fiber/request

pub fn new() -> backend.FiberBuilder {
  backend.FiberBuilder(
    methods: dict.new(),
    notifications: dict.new(),
    direction: option.None,
  )
}

pub fn on_request(
  builder builder: backend.FiberBuilder,
  method method: String,
  callback callback: backend.RequestCallback,
) -> backend.FiberBuilder {
  backend.FiberBuilder(
    ..builder,
    methods: builder.methods |> dict.insert(method, callback),
  )
}

pub fn on_notification(
  builder builder: backend.FiberBuilder,
  method method: String,
  callback callback: backend.NotificationCallback,
) -> backend.FiberBuilder {
  backend.FiberBuilder(
    ..builder,
    notifications: builder.notifications |> dict.insert(method, callback),
  )
}

pub fn bidirectional(builder: backend.FiberBuilder) -> backend.FiberBuilder {
  backend.FiberBuilder(
    ..builder,
    direction: option.Some(backend.BidirectionalDirection),
  )
}

pub fn client_only(builder: backend.FiberBuilder) -> backend.FiberBuilder {
  backend.FiberBuilder(
    ..builder,
    direction: option.Some(backend.ClientOnlyDirection),
  )
}

pub fn server_only(builder: backend.FiberBuilder) -> backend.FiberBuilder {
  backend.FiberBuilder(
    ..builder,
    direction: option.Some(backend.ServerOnlyDirection),
  )
}

pub type RequestError(a) {
  ReturnedError(message.ErrorData(Dynamic))
  DecodeError(List(decode.DecodeError))
  CallError(process.CallError(a))
}

pub fn call(
  fiber: backend.Fiber,
  request: request.Request(a),
  timeout timeout: Int,
) -> Result(a, RequestError(Result(Dynamic, message.ErrorData(Dynamic)))) {
  let id = request.id |> option.unwrap(message.StringId(uuid.v4_string()))

  let return =
    fiber
    |> process.try_call(
      backend.Request(request.method, request.params, id, _),
      timeout,
    )
    |> result.map_error(CallError)
    |> result.map(fn(call_result) {
      call_result
      |> result.map(fn(data) {
        decode.run(data, request.decoder)
        |> result.map_error(DecodeError)
      })
      |> result.map_error(ReturnedError)
      |> result.flatten
    })
    |> result.flatten

  fiber |> process.send(backend.RemoveWaiting(id))

  return
}

pub fn notify(fiber: backend.Fiber, request: request.Request(Dynamic)) -> Nil {
  fiber
  |> process.send(backend.Notification(request.method, request.params))
}

pub fn call_batch(
  fiber: backend.Fiber,
  requests: List(request.Request(a)),
  timeout timeout: Int,
) {
  let ids =
    requests
    |> list.filter_map(fn(request) {
      case request.id {
        option.None -> Error(Nil)
        option.Some(id) -> Ok(id)
      }
    })
    |> set.from_list

  let batch =
    requests
    |> list.map(fn(request) { #(request.method, request.params, request.id) })

  let return =
    fiber
    |> process.try_call(backend.Batch(batch, ids, _), timeout)
    |> result.map_error(CallError)

  fiber |> process.send(backend.RemoveWaitingBatch(ids))

  return
}

pub fn close(fiber: backend.Fiber) {
  fiber
  |> process.send(backend.Close)
}
