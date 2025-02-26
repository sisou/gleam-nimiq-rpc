import gleam/dynamic/decode.{type Decoder}

pub type Hash {
  Blake2b(hash: String)
  Argon2d(hash: String)
  Sha256(hash: String)
  Sha512(hash: String)
}

pub fn decoder() -> Decoder(Hash) {
  use algorithm <- decode.field("algorithm", decode.string)
  use hash <- decode.field("hash", decode.string)
  case algorithm {
    "blake2b" -> decode.success(Blake2b(hash))
    "argon2d" -> decode.success(Argon2d(hash))
    "sha256" -> decode.success(Sha256(hash))
    "sha512" -> decode.success(Sha512(hash))
    _ -> decode.failure(Blake2b(""), "Hash")
  }
}
