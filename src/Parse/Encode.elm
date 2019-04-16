module Parse.Encode exposing
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
import Json.Encode as Encode exposing (Value)
import Private.ObjectId exposing (..)
import Private.Pointer as Pointer exposing (Pointer)
import Private.SessionToken exposing (..)
import Time exposing (Posix)


{-| -}
sessionToken : SessionToken -> Value
sessionToken (SessionToken token) =
    Encode.string token


{-| -}
objectId : ObjectId a -> Value
objectId (ObjectId id) =
    Encode.string id


{-| -}
date : Posix -> Value
date posix =
    Encode.object
        [ ( "__type", Encode.string "Date" )
        , ( "iso", Encode.string (Iso8601.fromTime posix) )
        ]


{-| -}
pointer : Pointer a -> Value
pointer pointer_ =
    Encode.object
        [ ( "__type", Encode.string "Pointer" )
        , ( "className", Encode.string (Pointer.className pointer_) )
        , ( "objectId", objectId (Pointer.objectId pointer_) )
        ]
