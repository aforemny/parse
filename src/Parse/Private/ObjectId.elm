module Parse.Private.ObjectId exposing (ObjectId(..), fromString, toString, toValue)

import Json.Encode as Encode exposing (Value)


type ObjectId a
    = ObjectId String


toString : ObjectId a -> String
toString (ObjectId objectId) =
    objectId


toValue : ObjectId a -> Value
toValue objectId =
    Encode.string (toString objectId)


fromString : String -> ObjectId a
fromString objectId =
    ObjectId objectId
