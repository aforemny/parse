module Parse.Private.User exposing (deleteUser, emailVerificationRequest, getCurrentUser, getUser, logIn, passwordResetRequest, signUp, updateUser)

import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Parse.Decode as Decode
import Parse.Private.Object as Object exposing (Object)
import Parse.Private.ObjectId as ObjectId exposing (ObjectId)
import Parse.Private.Request as Request exposing (Request, request, requestWithAdditionalHeaders)
import Parse.Private.SessionToken as SessionToken exposing (SessionToken)
import Time exposing (Posix)
import Url


signUp :
    (user -> List ( String, Value ))
    -> String
    -> String
    -> user
    ->
        Request
            { createdAt : Posix
            , objectId : ObjectId a
            , sessionToken : SessionToken
            }
signUp encodeUser username password user =
    let
        body =
            [ ( "username", Encode.string username )
            , ( "password", Encode.string password )
            ]
                ++ encodeUser user
                |> Encode.object

        bodyDecoder location =
            Decode.map3
                (\createdAt objectId sessionToken ->
                    { createdAt = createdAt
                    , objectId = objectId
                    , sessionToken = sessionToken
                    , location = location
                    }
                )
                (Decode.field "createdAt" Decode.date)
                (Decode.field "objectId" Decode.objectId)
                (Decode.field "sessionToken" Decode.sessionToken)
    in
    requestWithAdditionalHeaders
        { method = "POST"
        , additionalHeaders =
            [ Http.header "X-Parse-Revocable-Session" "1" ]
        , endpoint = "/users"
        , body = Just body
        , decoder =
            Decode.succeed
                (\objectId createdAt sessionToken ->
                    { objectId = objectId
                    , createdAt = createdAt
                    , sessionToken = sessionToken
                    }
                )
                |> Decode.required "objectId" Decode.objectId
                |> Decode.required "createdAt" Decode.date
                |> Decode.required "sessionToken" SessionToken.decode
        }


logIn :
    Decoder user
    -> String
    -> String
    ->
        Request
            { user : user
            , sessionToken : SessionToken
            }
logIn userDecoder username password =
    let
        decoder =
            Decode.map2
                (\user sessionToken ->
                    { user = user
                    , sessionToken = sessionToken
                    }
                )
                userDecoder
                (Decode.field "sessionToken" Decode.sessionToken)
    in
    requestWithAdditionalHeaders
        { method = "GET"
        , additionalHeaders =
            [ Http.header "X-Parse-Revocable-Session" "1"
            ]
        , endpoint =
            String.concat
                [ "/login?username="
                , Url.percentEncode username
                , "&password="
                , Url.percentEncode password
                ]
        , body = Nothing
        , decoder = decoder
        }


emailVerificationRequest : String -> Request {}
emailVerificationRequest email =
    request
        { method = "POST"
        , endpoint = "/verificationEmailRequest"
        , body = Nothing
        , decoder = Decode.succeed {}
        }


passwordResetRequest : String -> Request {}
passwordResetRequest email =
    request
        { method = "POST"
        , endpoint = "/requestPasswordReset"
        , body = Nothing
        , decoder = Decode.succeed {}
        }


getUser : Decoder user -> ObjectId a -> Request user
getUser userDecoder objectId =
    request
        { method = "GET"
        , endpoint = "/users/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = userDecoder
        }


getCurrentUser : Decoder (Object user) -> Request (Object user)
getCurrentUser userDecoder =
    request
        { method = "GET"
        , endpoint = "/users/me"
        , body = Nothing
        , decoder = userDecoder
        }


updateUser :
    (user -> Value)
    -> ObjectId a
    -> user
    -> Request { updatedAt : Posix }
updateUser encodeUser objectId user =
    request
        { method = "PUT"
        , endpoint = "/users/" ++ ObjectId.toString objectId
        , body = Just (encodeUser user)
        , decoder =
            Decode.map (\updatedAt -> { updatedAt = updatedAt })
                (Decode.field "updatedAt" Decode.date)
        }


deleteUser : ObjectId a -> Request {}
deleteUser objectId =
    request
        { method = "DELETE"
        , endpoint = "/users/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = Decode.succeed {}
        }
