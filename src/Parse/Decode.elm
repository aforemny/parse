module Parse.Decode exposing
    ( sessionToken
    , objectId
    , date
    , pointer
    )

{-|

@docs sessionToken
@docs objectId
@docs date
@docs pointer

-}

import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Private.Decode as Decode
import Private.ObjectId exposing (..)
import Private.Pointer exposing (..)
import Private.SessionToken exposing (..)
import Time exposing (Posix)


{-| -}
sessionToken : Decoder SessionToken
sessionToken =
    Decode.map SessionToken Decode.string


{-| -}
objectId : Decoder (ObjectId a)
objectId =
    Decode.map ObjectId Decode.string


{-| -}
date : Decoder Posix
date =
    Decode.oneOf
        [ Iso8601.decoder
        , Decode.parseTypeDecoder "Date" <|
            Decode.field "iso" Iso8601.decoder
        ]


{-| -}
pointer : String -> Decoder (Pointer a)
pointer className =
    Decode.parseTypeDecoder "Pointer"
        (Decode.field "className" Decode.string
            |> Decode.andThen
                (\actualClassName ->
                    if actualClassName /= className then
                        [ "we expected a pointer for the class '"
                        , className
                        , "' but got a pointer for the class '"
                        , actualClassName
                        , "'"
                        ]
                            |> String.concat
                            |> Decode.fail

                    else
                        Decode.map (Pointer className)
                            (Decode.field "objectId" objectId)
                )
        )
