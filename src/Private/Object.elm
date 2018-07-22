module Private.Object exposing (Object, create, get, update, delete)

import Date exposing (Date)
import Private.ObjectId as ObjectId exposing (ObjectId)
import Private.Request as Request exposing (Request, request)
import Json.Decode as Decode exposing (Decoder, Value)


type alias Object a =
    { a
        | objectId : ObjectId a
        , createdAt : Date
        , updatedAt : Date
    }


create : String -> (a -> Value) -> a -> Request { objectId : ObjectId a, createdAt : Date }
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


update : String -> (b -> Value) -> ObjectId a -> b -> Request { updatedAt : Date }
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
