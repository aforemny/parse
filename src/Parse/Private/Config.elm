module Parse.Private.Config exposing (getConfig, updateConfig)

import Parse.Private.Request exposing (Request, request)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


getConfig : Decoder a -> Request a
getConfig decoder =
    request
        { method = "GET"
        , endpoint = "/config"
        , body = Nothing
        , decoder = Decode.at [ "params" ] decoder
        }


updateConfig : List ( String, Value ) -> Request Bool
updateConfig params =
    request
        { method = "GET"
        , endpoint = "/config"
        , body = Just <| Encode.object [ ( "params", Encode.object params ) ]
        , decoder = Decode.at [ "result" ] Decode.bool
        }
