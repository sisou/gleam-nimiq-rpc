import gleam/bit_array
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result

import fiber
import fiber/backend
import fiber/message

fn send_request(
  url: String,
  authentication: Option(#(String, String)),
  payload: String,
) -> Result(response.Response(String), httpc.HttpError) {
  // Prepare a HTTP request record
  let assert Ok(base_req) = request.to(url)

  let req =
    base_req
    |> request.set_method(http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(payload)

  let req = case authentication {
    Some(#(username, password)) -> {
      let auth = username <> ":" <> password
      req
      |> request.set_header(
        "authorization",
        "Basic "
          <> auth |> bit_array.from_string() |> bit_array.base64_encode(True),
      )
    }
    None -> req
  }

  // Send the HTTP request to the server
  httpc.send(req)
}

pub type Client =
  backend.Fiber

fn start_client(
  url: String,
  authentication: Option(#(String, String)),
) -> Client {
  let state = fiber.new() |> backend.build_state()

  let assert Ok(actor) =
    actor.start(state, fn(msg, state) {
      let response_subject = process.new_subject()
      let next =
        state
        |> backend.fiber_message(msg, fn(payload) {
          send_request(
            url,
            authentication,
            payload |> message.to_json() |> json.to_string(),
          )
          |> result.map(fn(res) { response_subject |> process.send(res.body) })
        })

      case next {
        actor.Continue(next_state, _) -> {
          case response_subject |> process.receive(0) {
            Ok(response) -> {
              let _ = next_state |> backend.handle_text(response)
              Nil
            }
            _ -> Nil
          }
          actor.continue(next_state)
        }
        actor.Stop(reason) -> actor.Stop(reason)
      }
    })
  actor
}

pub fn client(url: String) -> Client {
  start_client(url, None)
}

pub fn client_with_auth(
  url: String,
  username: String,
  password: String,
) -> Client {
  start_client(url, Some(#(username, password)))
}
