module Parse.Private.CloudCode exposing (function, job)

import Json.Decode as Decode exposing (Decoder, Value)
import Parse.Private.Request exposing (Request, request)


function : String -> Decoder a -> Value -> Request a
function name decoder value =
    request
        { method = "POST"
        , endpoint = "/functions/" ++ name
        , body = Just value
        , decoder = Decode.at [ "result" ] decoder
        }


job : String -> Value -> Request {}
job name value =
    request
        { method = "POST"
        , endpoint = "/jobs/" ++ name
        , body = Just value
        , decoder = Decode.succeed {}
        }
