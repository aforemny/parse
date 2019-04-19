module Parse.Private.SessionToken exposing
    ( SessionToken(..)
    , decode
    , encode
    , fromString
    , toString
    )

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


type SessionToken
    = SessionToken String


toString : SessionToken -> String
toString (SessionToken sessionToken) =
    sessionToken


fromString : String -> SessionToken
fromString sessionToken =
    SessionToken sessionToken


decode : Decoder SessionToken
decode =
    Decode.map fromString Decode.string


encode : SessionToken -> Value
encode sessionToken =
    Encode.string (toString sessionToken)
