module Parse.Private.Decode exposing (parseTypeDecoder)

import Json.Decode as Decode exposing (Decoder)


{-| -}
parseTypeDecoder : String -> Decoder a -> Decoder a
parseTypeDecoder expectedType decoder =
    Decode.field "__type" Decode.string
        |> Decode.andThen
            (\actualType ->
                if actualType /= expectedType then
                    [ "we expected a field of the Parse type '"
                    , expectedType
                    , "' but the Parse type is '"
                    , actualType
                    , "'"
                    ]
                        |> String.concat
                        |> Decode.fail

                else
                    decoder
            )
