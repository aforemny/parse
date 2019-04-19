module Parse.Private.Object exposing (Object, create, delete, get, update)

import Json.Decode as Decode exposing (Decoder, Value)
import Parse.Private.ObjectId as ObjectId exposing (ObjectId)
import Parse.Private.Request as Request exposing (Request, request)
import Time exposing (Posix)


type alias Object a =
    { a
        | objectId : ObjectId a
        , createdAt : Posix
        , updatedAt : Posix
    }


create : String -> (a -> Value) -> a -> Request { objectId : ObjectId a, createdAt : Posix }
create className encodeObject object =
    request
        { method = "POST"
        , endpoint = "/classes/" ++ className
        , body = Just (encodeObject object)
        , decoder = Request.postDecoder
        }


get : String -> Decoder (Object a) -> ObjectId a -> Request (Object a)
get className objectDecoder objectId =
    request
        { method = "GET"
        , endpoint = "/classes/" ++ className ++ "/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = objectDecoder
        }


update : String -> (b -> Value) -> ObjectId a -> b -> Request { updatedAt : Posix }
update className encodeObject objectId object =
    request
        { method = "PUT"
        , endpoint = "/classes/" ++ className ++ "/" ++ ObjectId.toString objectId
        , body = Just (encodeObject object)
        , decoder = Request.putDecoder
        }


delete : String -> ObjectId a -> Request {}
delete className objectId =
    request
        { method = "DELETE"
        , endpoint = "/classes/" ++ className ++ "/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = Decode.succeed {}
        }
