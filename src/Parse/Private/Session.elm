module Parse.Private.Session exposing
    ( Action(..)
    , AuthProvider(..)
    , CreatedWith(..)
    , Session
    , actionDecoder
    , authProviderDecoder
    , createDecoder
    , createSession
    , createdWithDecoder
    , deleteSession
    , encodeAction
    , encodeAuthProvider
    , encodeCreatedWith
    , encodeSession
    , getSession
    , getSessions
    , sessionDecoder
    , updateSession
    )

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Parse.Decode as Decode
import Parse.Encode as Encode
import Parse.Private.Object as Object exposing (Object)
import Parse.Private.ObjectId as ObjectId exposing (ObjectId)
import Parse.Private.Pointer as Pointer exposing (Pointer)
import Parse.Private.Request as Request exposing (Request, request)
import Parse.Private.SessionToken as SessionToken exposing (SessionToken)
import Time exposing (Posix)


type alias Session user =
    { sessionToken : SessionToken
    , user : Pointer user
    , createdWith : CreatedWith
    , restricted : Bool
    , expiresAt : Posix
    , installationId : String
    }


encodeSession : Session user -> Value
encodeSession session =
    Encode.object
        [ ( "sessionToken", Encode.sessionToken session.sessionToken )
        , ( "user", Encode.pointer session.user )
        , ( "createdWith", encodeCreatedWith session.createdWith )
        , ( "restricted", Encode.bool session.restricted )
        , ( "expiresAt", Encode.date session.expiresAt )
        , ( "installationId", Encode.string session.installationId )
        ]


sessionDecoder : Decoder (Object (Session user))
sessionDecoder =
    Decode.succeed
        (\objectId createdAt updatedAt sessionToken user createdWith restricted expiresAt installationId ->
            { objectId = objectId
            , createdAt = createdAt
            , updatedAt = updatedAt
            , sessionToken = sessionToken
            , user = user
            , createdWith = createdWith
            , restricted = restricted
            , expiresAt = expiresAt
            , installationId = installationId
            }
        )
        |> Decode.required "objectId" Decode.objectId
        |> Decode.required "createdAt" Decode.date
        |> Decode.required "updatedAt" Decode.date
        |> Decode.required "sessionToken" Decode.sessionToken
        |> Decode.required "user" (Decode.pointer "_User")
        |> Decode.required "createdWith" createdWithDecoder
        |> Decode.required "restricted" Decode.bool
        |> Decode.required "expiresAt" Decode.date
        |> Decode.required "installationid" Decode.string


createSession :
    Session user
    ->
        Request
            { createdAt : Posix
            , createdWith : CreatedWith
            , objectId : ObjectId (Session user)
            , restricted : Bool
            , sessionToken : SessionToken
            }
createSession session =
    request
        { method = "POST"
        , endpoint = "/sessions"
        , body = Just (encodeSession session)
        , decoder = createDecoder
        }


getSession : ObjectId (Session user) -> Request (Object (Session user))
getSession objectId =
    request
        { method = "GET"
        , endpoint = "/sessions/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = sessionDecoder
        }


updateSession : (b -> Value) -> ObjectId a -> b -> Request { updatedAt : Posix }
updateSession encodeObject objectId object =
    request
        { method = "PUT"
        , endpoint = "/sessions/" ++ ObjectId.toString objectId
        , body = Just (encodeObject object)
        , decoder = Request.putDecoder
        }


getSessions : Request (List (Object (Session user)))
getSessions =
    request
        { method = "GET"
        , endpoint = "/sessions"
        , body = Nothing
        , decoder = Decode.list sessionDecoder
        }


deleteSession : ObjectId (Session user) -> Request {}
deleteSession objectId =
    request
        { method = "DELETE"
        , endpoint = "/sessions/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = Decode.succeed {}
        }


createDecoder :
    Decoder
        { createdAt : Posix
        , createdWith : CreatedWith
        , objectId : ObjectId (Session user)
        , restricted : Bool
        , sessionToken : SessionToken
        }
createDecoder =
    Decode.succeed
        (\createdAt createdWith objectId restricted sessionToken ->
            { createdAt = createdAt
            , createdWith = createdWith
            , objectId = objectId
            , restricted = restricted
            , sessionToken = sessionToken
            }
        )
        |> Decode.required "createdAt" Decode.date
        |> Decode.required "createdWith" createdWithDecoder
        |> Decode.required "objectId" Decode.objectId
        |> Decode.required "restricted" Decode.bool
        |> Decode.required "sessionToken" Decode.sessionToken


type CreatedWith
    = CreatedWith
        { action : Action
        , authProvider : AuthProvider
        }


encodeCreatedWith : CreatedWith -> Value
encodeCreatedWith (CreatedWith createdWith_) =
    Encode.object
        [ ( "action", encodeAction createdWith_.action )
        , ( "authProvider", encodeAuthProvider createdWith_.authProvider )
        ]


createdWithDecoder : Decoder CreatedWith
createdWithDecoder =
    Decode.succeed
        (\action authProvider ->
            CreatedWith { action = action, authProvider = authProvider }
        )
        |> Decode.required "action" actionDecoder
        |> Decode.required "authProvider" authProviderDecoder


type Action
    = Signup
    | Login
    | Create
    | Upgrade


encodeAction : Action -> Value
encodeAction action =
    Encode.string <|
        case action of
            Signup ->
                "signup"

            Login ->
                "login"

            Create ->
                "create"

            Upgrade ->
                "upgrade"


actionDecoder : Decoder Action
actionDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "signup" ->
                        Decode.succeed Signup

                    "login" ->
                        Decode.succeed Login

                    "create" ->
                        Decode.succeed Create

                    "upgrade" ->
                        Decode.succeed Upgrade

                    _ ->
                        [ "we expected a string of "
                        , "password', 'anonymous', 'facebook', 'twitter'"
                        , " but the string is '"
                        , string
                        , "'"
                        ]
                            |> String.concat
                            |> Decode.fail
            )


type AuthProvider
    = Password
    | Anonymous
    | Facebook
    | Twitter


encodeAuthProvider : AuthProvider -> Value
encodeAuthProvider authProvider =
    Encode.string <|
        case authProvider of
            Password ->
                "password"

            Anonymous ->
                "anonymous"

            Facebook ->
                "facebook"

            Twitter ->
                "twitter"


authProviderDecoder : Decoder AuthProvider
authProviderDecoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "password" ->
                        Decode.succeed Password

                    "anonymous" ->
                        Decode.succeed Anonymous

                    "facebook" ->
                        Decode.succeed Facebook

                    "twitter" ->
                        Decode.succeed Twitter

                    _ ->
                        [ "we expected a string of '"
                        , "password', 'anonymous', 'facebook', 'twitter'"
                        , "' but the string is '"
                        , string
                        , "'"
                        ]
                            |> String.concat
                            |> Decode.fail
            )
