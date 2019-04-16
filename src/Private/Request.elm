module Private.Request exposing
    ( Config
    , Request
    , postDecoder
    , putDecoder
    , request
    , requestWithAdditionalHeaders
    , send
    , simpleConfig
    , toTask
    )

import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Parse.Decode as Decode
import Private.Error as Error exposing (Error)
import Private.ObjectId as ObjectId exposing (ObjectId)
import Private.SessionToken as SessionToken exposing (SessionToken)
import Task exposing (Task)
import Time exposing (Posix)


{-| -}
type alias Config =
    { serverUrl : String
    , applicationId : String
    , restAPIKey : Maybe String
    , javascriptKey : Maybe String
    , clientKey : Maybe String
    , windowsKey : Maybe String
    , masterKey : Maybe String
    , sessionToken : Maybe SessionToken
    }


simpleConfig : String -> String -> Config
simpleConfig serverUrl applicationId =
    Config
        serverUrl
        applicationId
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing


type Request a
    = Request
        { runRequest :
            Config
            ->
                { method : String
                , headers : List Http.Header
                , url : String
                , body : Http.Body
                , resolver : Http.Resolver Http.Error a
                , timeout : Maybe Float
                }
        }


headers : Config -> List Http.Header
headers config =
    List.filterMap identity
        [ Just (Http.header "X-Parse-Application-Id" config.applicationId)
        , config.restAPIKey
            |> Maybe.map (Http.header "X-Parse-REST-API-Key")
        , config.javascriptKey
            |> Maybe.map (Http.header "X-Parse-JavaScript-Key")
        , config.clientKey
            |> Maybe.map (Http.header "X-Parse-Client-Key")
        , config.windowsKey
            |> Maybe.map (Http.header "X-Parse-Windows-Key")
        , config.masterKey
            |> Maybe.map (Http.header "X-Parse-Master-Key")
        , config.sessionToken
            |> Maybe.map SessionToken.toString
            |> Maybe.map (Http.header "X-Parse-Session-Token")
        ]


request :
    { method : String
    , endpoint : String
    , body : Maybe Value
    , decoder : Decoder a
    }
    -> Request a
request { method, endpoint, body, decoder } =
    requestWithAdditionalHeaders
        { method = method
        , additionalHeaders = []
        , endpoint = endpoint
        , body = body
        , decoder = decoder
        }


requestWithAdditionalHeaders :
    { method : String
    , additionalHeaders : List Http.Header
    , endpoint : String
    , body : Maybe Value
    , decoder : Decoder a
    }
    -> Request a
requestWithAdditionalHeaders { method, additionalHeaders, endpoint, body, decoder } =
    Request <|
        { runRequest =
            \config ->
                { method = method
                , headers = headers config ++ additionalHeaders
                , url = config.serverUrl ++ endpoint
                , body =
                    Maybe.map Http.jsonBody body
                        |> Maybe.withDefault Http.emptyBody
                , resolver =
                    Http.stringResolver
                        (\response ->
                            case response of
                                Http.BadUrl_ url ->
                                    Err (Http.BadUrl url)

                                Http.Timeout_ ->
                                    Err Http.Timeout

                                Http.NetworkError_ ->
                                    Err Http.NetworkError

                                Http.BadStatus_ metadata body_ ->
                                    Err (Http.BadStatus metadata.statusCode)

                                Http.GoodStatus_ metadata body_ ->
                                    case Decode.decodeString decoder body_ of
                                        Ok value ->
                                            Ok value

                                        Err err ->
                                            Err (Http.BadBody (Decode.errorToString err))
                        )
                , timeout = Nothing
                }
        }



-- TODO:?
--        |> Http.toTask
--        |> Task.mapError
--            (\httpError ->
--                case httpError of
--                    Http.BadStatus { status, body } ->
--                        case Decode.decodeString errorDecoder body of
--                            Ok parseError ->
--                                ParseError parseError
--
--                            Err decodeError ->
--                                DecodeError decodeError
--
--                    _ ->
--                        HttpError httpError
--            )


toTask : Config -> Request a -> Task Error a
toTask config (Request { runRequest }) =
    Http.task (runRequest config)
        |> Task.mapError Error.HttpError


send : Config -> (Result Error a -> m) -> Request a -> Cmd m
send config handle request_ =
    Task.attempt handle (toTask config request_)


postDecoder : Decoder { objectId : ObjectId a, createdAt : Posix }
postDecoder =
    Decode.map2 (\createdAt objectId -> { createdAt = createdAt, objectId = objectId })
        (Decode.field "createdAt" Decode.date)
        (Decode.field "objectId" Decode.objectId)


putDecoder : Decoder { updatedAt : Posix }
putDecoder =
    Decode.map (\updatedAt -> { updatedAt = updatedAt })
        (Decode.field "updatedAt" Decode.date)
