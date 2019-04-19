module Parse.Private.ObjectId exposing (ObjectId(..), fromString, toString)


type ObjectId a
    = ObjectId String


toString : ObjectId a -> String
toString (ObjectId objectId) =
    objectId


fromString : String -> ObjectId a
fromString objectId =
    ObjectId objectId
