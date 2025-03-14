import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/erlang/process
import gleam/function
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/result
import gleam/set
import gleam/string

import fiber/message
import fiber/response

pub type RequestCallback =
  fn(Option(Dynamic)) -> Result(Json, response.Error)

pub type NotificationCallback =
  fn(Option(Dynamic)) -> Nil

type RequestReplySubject =
  process.Subject(Result(Dynamic, message.ErrorData(Dynamic)))

type BatchReqeustReplySubject =
  process.Subject(Dict(message.Id, Result(Dynamic, message.ErrorData(Dynamic))))

pub type Direction {
  ServerOnlyDirection
  ClientOnlyDirection
  BidirectionalDirection
}

pub type FiberBuilder {
  FiberBuilder(
    methods: Dict(String, RequestCallback),
    notifications: Dict(String, NotificationCallback),
    direction: Option(Direction),
  )
}

type ClientState {
  ClientState(
    waiting: Dict(message.Id, RequestReplySubject),
    waiting_batches: Dict(set.Set(message.Id), BatchReqeustReplySubject),
  )
}

type ServerState {
  ServerState(
    methods: Dict(String, RequestCallback),
    notifications: Dict(String, NotificationCallback),
  )
}

pub opaque type FiberState {
  ClientOnly(client_state: ClientState)
  ServerOnly(server_state: ServerState)
  Bidirectional(client_state: ClientState, server_state: ServerState)
}

pub type Message {
  Request(
    method: String,
    params: Option(Json),
    id: message.Id,
    reply_subject: process.Subject(Result(Dynamic, message.ErrorData(Dynamic))),
  )
  Notification(method: String, params: Option(Json))
  Batch(
    requests: List(#(String, Option(Json), Option(message.Id))),
    ids: set.Set(message.Id),
    reply_subject: process.Subject(
      Dict(message.Id, Result(Dynamic, message.ErrorData(Dynamic))),
    ),
  )
  RemoveWaiting(id: message.Id)
  RemoveWaitingBatch(ids: set.Set(message.Id))
  Close
}

pub type Fiber =
  process.Subject(Message)

pub fn build_state(builder: FiberBuilder) -> FiberState {
  let direction =
    option.lazy_unwrap(builder.direction, fn() {
      case
        dict.is_empty(builder.methods) && dict.is_empty(builder.notifications)
      {
        True -> ClientOnlyDirection
        False -> ServerOnlyDirection
      }
    })
  case direction {
    BidirectionalDirection ->
      Bidirectional(
        server_state: ServerState(
          methods: builder.methods,
          notifications: builder.notifications,
        ),
        client_state: ClientState(
          waiting: dict.new(),
          waiting_batches: dict.new(),
        ),
      )
    ClientOnlyDirection ->
      ClientOnly(client_state: ClientState(
        waiting: dict.new(),
        waiting_batches: dict.new(),
      ))
    ServerOnlyDirection ->
      ServerOnly(server_state: ServerState(
        methods: builder.methods,
        notifications: builder.notifications,
      ))
  }
}

pub fn wrap(
  establish: fn(fn() -> process.Selector(Message)) -> Result(anything, error),
) -> Result(Fiber, error) {
  let send_back = process.new_subject()

  let bind_selector = fn() {
    let subject = process.new_subject()

    process.send(send_back, subject)

    process.new_selector()
    |> process.selecting(subject, function.identity)
  }

  use _ <- result.map(establish(bind_selector))

  process.new_selector()
  |> process.selecting(send_back, function.identity)
  |> process.select_forever
}

pub fn stop_on_error(result: Result(a, b), state: d) -> actor.Next(c, d) {
  case result {
    Error(e) -> {
      let reason = string.inspect(e)
      io.print_error("Fiber closed due to " <> reason)
      actor.Stop(process.Abnormal(reason))
    }
    Ok(_) -> actor.continue(state)
  }
}

fn add_waiting(
  connection: FiberState,
  id: message.Id,
  reply: process.Subject(Result(Dynamic, message.ErrorData(Dynamic))),
) -> FiberState {
  case connection {
    Bidirectional(ClientState(waiting, waiting_batches), server_state) ->
      Bidirectional(
        server_state:,
        client_state: ClientState(
          waiting_batches:,
          waiting: waiting |> dict.insert(id, reply),
        ),
      )
    ClientOnly(ClientState(waiting, waiting_batches)) ->
      ClientOnly(client_state: ClientState(
        waiting_batches:,
        waiting: waiting |> dict.insert(id, reply),
      ))
    _ -> connection
  }
}

fn add_waiting_batch(
  connection: FiberState,
  ids: set.Set(message.Id),
  reply: process.Subject(
    Dict(message.Id, Result(Dynamic, message.ErrorData(Dynamic))),
  ),
) -> FiberState {
  case connection {
    Bidirectional(ClientState(waiting, waiting_batches), server_state) ->
      Bidirectional(
        server_state:,
        client_state: ClientState(
          waiting:,
          waiting_batches: waiting_batches
            |> dict.insert(ids, reply),
        ),
      )
    ClientOnly(ClientState(waiting, waiting_batches)) ->
      ClientOnly(client_state: ClientState(
        waiting:,
        waiting_batches: waiting_batches
          |> dict.insert(ids, reply),
      ))
    _ -> connection
  }
}

fn remove_waiting(connection: FiberState, id: message.Id) -> FiberState {
  case connection {
    Bidirectional(ClientState(waiting, waiting_batches), server_state) ->
      Bidirectional(
        server_state:,
        client_state: ClientState(
          waiting_batches:,
          waiting: waiting |> dict.delete(id),
        ),
      )
    ClientOnly(ClientState(waiting, waiting_batches)) ->
      ClientOnly(client_state: ClientState(
        waiting_batches:,
        waiting: waiting |> dict.delete(id),
      ))
    _ -> connection
  }
}

fn remove_waiting_batch(
  connection: FiberState,
  ids: set.Set(message.Id),
) -> FiberState {
  case connection {
    Bidirectional(ClientState(waiting, waiting_batches), server_state) ->
      Bidirectional(
        server_state:,
        client_state: ClientState(
          waiting:,
          waiting_batches: waiting_batches |> dict.delete(ids),
        ),
      )
    ClientOnly(ClientState(waiting, waiting_batches)) ->
      ClientOnly(client_state: ClientState(
        waiting:,
        waiting_batches: waiting_batches |> dict.delete(ids),
      ))
    _ -> connection
  }
}

pub fn handle_text(
  state: FiberState,
  message text: String,
) -> Result(message.Message(Json), Nil) {
  case message.decode(text) {
    Error(error) -> {
      case error {
        json.UnexpectedFormat(_) ->
          message.ErrorData(
            code: -32_600,
            message: "Invalid Request",
            data: option.None,
          )
        json.UnableToDecode(_) ->
          message.ErrorData(
            code: -32_600,
            message: "Invalid Request",
            data: option.None,
          )
        json.UnexpectedByte(byte) ->
          message.ErrorData(
            code: -32_700,
            message: "Parse error",
            data: option.Some(json.string("Unexpected Byte: \"" <> byte <> "\"")),
          )

        json.UnexpectedEndOfInput ->
          message.ErrorData(
            code: -32_700,
            message: "Parse error",
            data: option.Some(json.string("Unexpected End of Input")),
          )
        json.UnexpectedSequence(sequence) ->
          message.ErrorData(
            code: -32_700,
            message: "Parse error",
            data: option.Some(json.string(
              "Unexpected Sequence: \"" <> sequence <> "\"",
            )),
          )
      }
      |> message.ErrorMessage
      |> Ok
    }
    Ok(message) -> handle_message(state, message)
  }
}

pub fn fiber_message(
  state: FiberState,
  message message: Message,
  send send: fn(message.Message(Json)) -> Result(a, b),
) -> actor.Next(m, FiberState) {
  case message {
    Request(method, params, id, reply_subject) -> {
      message.Request(params, method, id)
      |> message.RequestMessage
      |> send
      |> stop_on_error(state |> add_waiting(id, reply_subject))
    }
    Notification(method, params) -> {
      message.Notification(params, method)
      |> message.RequestMessage
      |> send
      |> stop_on_error(state)
    }
    Batch(batch, ids, reply_subject) -> {
      batch
      |> list.map(fn(request) {
        let #(method, params, id) = request
        case id {
          option.None -> message.Notification(params, method)
          option.Some(id) -> message.Request(params, method, id)
        }
      })
      |> message.BatchRequestMessage
      |> send
      |> stop_on_error(state |> add_waiting_batch(ids, reply_subject))
    }
    RemoveWaiting(id) -> actor.continue(state |> remove_waiting(id))
    RemoveWaitingBatch(ids) ->
      actor.continue(state |> remove_waiting_batch(ids))
    Close -> actor.Stop(process.Normal)
  }
}

pub fn handle_binary(
  state: FiberState,
  message _binary: BitArray,
) -> Result(message.Message(Json), Nil) {
  case state {
    Bidirectional(_, _) | ServerOnly(_) ->
      message.ErrorData(
        code: -32_700,
        message: "Parse error",
        data: option.Some(json.string("binary frames are unsupported")),
      )
      |> message.ErrorMessage
      |> Ok
    ClientOnly(_) -> {
      // we can't reply to this, so just log an error
      io.println_error(
        "Received binary data, which is unsupported by this backend",
      )
      Error(Nil)
    }
  }
}

fn handle_request_callback_result(
  result: Result(Json, response.Error),
  id: message.Id,
) -> message.Response(Json) {
  case result {
    Error(response.InvalidParams) -> {
      option.None
      |> message.ErrorData(code: -32_602, message: "Invalid params")
      |> message.ErrorResponse(id:)
    }
    Error(response.InternalError) -> {
      option.None
      |> message.ErrorData(code: -32_603, message: "Internal error")
      |> message.ErrorResponse(id:)
    }
    Error(response.CustomError(error)) -> {
      error
      |> message.ErrorResponse(id:)
    }
    Ok(result) -> {
      result
      |> message.SuccessResponse(id:)
    }
  }
}

fn process_request(
  server_state: ServerState,
  request: message.Request(Dynamic),
) -> Result(message.Response(Json), Nil) {
  case request {
    message.Notification(params, method) ->
      case server_state.notifications |> dict.get(method) {
        Error(Nil) -> {
          // simply ignore  and log unknown notifications, as the spec says never to reply to them
          io.println_error(
            "Received notification we don't have a handler for: "
            <> method
            <> ", params: "
            <> string.inspect(params),
          )
          Error(Nil)
        }
        Ok(callback) -> {
          callback(params)
          Error(Nil)
        }
      }
    message.Request(params, method, id) ->
      case server_state.methods |> dict.get(method) {
        Error(Nil) -> {
          option.Some(json.string(method))
          |> message.ErrorData(code: -32_601, message: "Method not found")
          |> message.ErrorResponse(id:)
          |> Ok
        }
        Ok(callback) -> {
          callback(params)
          |> handle_request_callback_result(id)
          |> Ok
        }
      }
  }
}

fn handle_response(
  client_state: ClientState,
  response: message.Response(Dynamic),
) -> Nil {
  case response {
    message.ErrorResponse(error, id) ->
      case client_state.waiting |> dict.get(id) {
        Error(Nil) -> {
          // we can't reply to this, so just log an error
          io.println_error(
            "Received error for id that we were not waiting for (it possibly timed out): "
            <> string.inspect(id)
            <> ", error: "
            <> string.inspect(error),
          )
        }
        Ok(reply_subject) -> {
          reply_subject |> process.send(Error(error))
        }
      }
    message.SuccessResponse(result, id) ->
      case client_state.waiting |> dict.get(id) {
        Error(Nil) -> {
          // we can't reply to this, so just log an error
          io.println_error(
            "Received response for id that we were not waiting for (it possibly timed out): "
            <> string.inspect(id)
            <> ", result: "
            <> string.inspect(result),
          )
        }
        Ok(reply_subject) -> {
          reply_subject |> process.send(Ok(result))
        }
      }
  }
}

fn handle_batch_request(
  server_state: ServerState,
  batch: List(message.Request(Dynamic)),
) -> Result(message.Message(Json), Nil) {
  let responses =
    batch
    |> list.map(process_request(server_state, _))
    |> result.values

  case responses {
    [] -> Error(Nil)
    responses ->
      responses
      |> message.BatchResponseMessage
      |> Ok
  }
}

fn handle_batch_response(
  client_state: ClientState,
  batch: List(message.Response(Dynamic)),
) -> Nil {
  let ids =
    batch
    |> list.map(fn(response) {
      case response {
        message.ErrorResponse(_, id) -> id
        message.SuccessResponse(_, id) -> id
      }
    })
    |> set.from_list

  case client_state.waiting_batches |> dict.get(ids) {
    Error(Nil) -> {
      // we can't reply to this, so just log an error
      io.println_error(
        "Received batch response for an id set that we were not waiting for (it possibly timed out): "
        <> string.inspect(ids),
      )
    }
    Ok(reply_subject) -> {
      batch
      |> list.map(fn(response) {
        case response {
          message.ErrorResponse(error, id) -> #(id, Error(error))
          message.SuccessResponse(result, id) -> #(id, Ok(result))
        }
      })
      |> dict.from_list
      |> process.send(reply_subject, _)
    }
  }
}

fn handle_message(
  state: FiberState,
  message fiber_message: message.Message(Dynamic),
) -> Result(message.Message(Json), Nil) {
  case fiber_message {
    message.BatchRequestMessage(batch) ->
      case state {
        ServerOnly(server_state) | Bidirectional(_, server_state) ->
          handle_batch_request(server_state, batch)

        _ -> Error(Nil)
      }

    message.BatchResponseMessage(batch) ->
      case state {
        ClientOnly(client_state) | Bidirectional(client_state, _) ->
          Error(handle_batch_response(client_state, batch))
        _ -> Error(Nil)
      }

    message.RequestMessage(request) ->
      case state {
        ServerOnly(server_state) | Bidirectional(_, server_state) ->
          case process_request(server_state, request) {
            Error(Nil) -> Error(Nil)
            Ok(response) ->
              response
              |> message.ResponseMessage
              |> Ok
          }

        _ -> Error(Nil)
      }

    message.ResponseMessage(response) ->
      case state {
        ClientOnly(client_state) | Bidirectional(client_state, _) ->
          Error(handle_response(client_state, response))

        _ -> Error(Nil)
      }

    message.ErrorMessage(error) -> {
      // we can't reply to this according to the spec, so just log an error
      io.println_error(
        "Received error without id (usually indicates we sent malformed data): "
        <> string.inspect(error),
      )

      Error(Nil)
    }
  }
}
