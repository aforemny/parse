module Private.Analytics exposing (Event, post, postAt)

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Parse.Decode as Decode
import Parse.Encode as Encode
import Private.Request exposing (Request, request)
import Time exposing (Posix)


type alias Event a =
    { a
        | eventName : String
    }


{-| -}
post : (Event a -> List ( String, Value )) -> Event a -> Request {}
post encode event =
    request
        { method = "POST"
        , endpoint = "/events/" ++ event.eventName
        , body = Just (Encode.object (encode event))
        , decoder = Decode.succeed {}
        }


{-| @todo(aforemny) Encoders _should_ be a -> List (String, Value)
-}
postAt : (Event a -> List ( String, Value )) -> Posix -> Event a -> Request {}
postAt encode date event =
    request
        { method = "POST"
        , endpoint = "/events/" ++ event.eventName
        , body = Just (Encode.object (( "at", Encode.date date ) :: encode event))
        , decoder = Decode.succeed {}
        }
