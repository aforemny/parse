module Parse.Encode
    exposing
        ( date
        , objectId
        , pointer
        , sessionToken
        )

{-|

@docs sessionToken

@docs objectId

@docs date

@docs pointer

-}

import Date exposing (Date)
import Private.ObjectId exposing (..)
import Private.Pointer exposing (Pointer(..))
import Private.SessionToken exposing (..)
import Json.Encode as Encode exposing (Value)
import Time.DateTime


{-| -}
sessionToken : SessionToken -> Value
sessionToken (SessionToken token) =
    Encode.string token


{-| -}
objectId : ObjectId a -> Value
objectId (ObjectId id) =
    Encode.string id


{-| -}
date : Date -> Value
date date =
    [ ( "__type", Encode.string "Date" )
    , ( "iso"
      , date
            |> Date.toTime
            |> Time.DateTime.fromTimestamp
            |> Time.DateTime.toISO8601
            |> Encode.string
      )
    ]
        |> Encode.object


{-| -}
pointer : String -> Pointer a -> Value
pointer className pointer =
  case pointer of
    Pointer className id ->
        [ ( "__type", Encode.string "Pointer" )
        , ( "className", Encode.string className )
        , ( "objectId", objectId id )
        ]
            |> Encode.object
