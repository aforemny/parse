module Main exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html, text, program)
import Json.Decode as Json exposing (Decoder, Value)
import Json.Decode.Pipeline as Json
import Parse.Config
import Parse.LiveQuery as LiveQuery
import Parse.LiveQueryClient as LiveQueryClient
import Parse.LiveQueryClient.Internal
import Parse.Query


main =
    program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { liveQueryClient : LiveQueryClient.Model Msg
    , userOpen : Bool
    , userEvents : List (LiveQuery.Msg User)
    , users : Dict String User
    }


defaultModel : Model
defaultModel =
    { liveQueryClient = LiveQueryClient.defaultModel
    , userOpen = False
    , userEvents = []
    , users = Dict.empty
    }


type Msg
    = LiveQueryClientMsg Parse.LiveQueryClient.Internal.Msg
    | UserMsg (Result String (LiveQuery.Msg User))


parseConfig : Parse.Config.Config
parseConfig =
    { serverUrl = "ws://localhost:1337/parse"
    , applicationId = "test"
    , masterKey = Just "test"
    , javascriptKey = Nothing
    , restAPIKey = Nothing
    , sessionToken = Nothing
    , clientKey = Nothing
    , windowsKey = Nothing
    }


init : ( Model, Cmd Msg )
init =
    let
        ( liveQueryClient, liveQueryClientCmds ) =
            LiveQueryClient.init parseConfig
                [ LiveQueryClient.subscribe userQuery decodeUser UserMsg
                ]
    in
        ( { defaultModel | liveQueryClient = liveQueryClient }
        , liveQueryClientCmds
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    LiveQueryClient.subscription LiveQueryClientMsg parseConfig model.liveQueryClient


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "Msg" msg of
        LiveQueryClientMsg msg_ ->
            let
                ( liveQueryClient, cmds ) =
                    LiveQueryClient.update parseConfig msg_ model.liveQueryClient
            in
                ( { model | liveQueryClient = liveQueryClient }, cmds )

        UserMsg (Err err) ->
            let
                _ =
                    Debug.log "UserMsg" err
            in
                ( model, Cmd.none )

        UserMsg (Ok ((LiveQuery.Open) as event)) ->
            ( { model | userOpen = True, userEvents = event :: model.userEvents }
            , Cmd.none
            )

        UserMsg (Ok ((LiveQuery.Close) as event)) ->
            ( { model | userOpen = False, userEvents = event :: model.userEvents }
            , Cmd.none
            )

        UserMsg (Ok ((LiveQuery.Create user) as event)) ->
            ( { model
                | users = Dict.insert user.objectId user model.users
                , userEvents = event :: model.userEvents
              }
            , Cmd.none
            )

        UserMsg (Ok ((LiveQuery.Update user) as event)) ->
            ( { model
                | users = Dict.insert user.objectId user model.users
                , userEvents = event :: model.userEvents
              }
            , Cmd.none
            )

        UserMsg (Ok ((LiveQuery.Enter user) as event)) ->
            ( { model | userEvents = event :: model.userEvents }, Cmd.none )

        UserMsg (Ok ((LiveQuery.Leave user) as event)) ->
            ( { model | userEvents = event :: model.userEvents }, Cmd.none )

        UserMsg (Ok ((LiveQuery.Delete user) as event)) ->
            ( { model
                | users = Dict.remove user.objectId model.users
                , userEvents = event :: model.userEvents
              }
            , Cmd.none
            )


type alias User =
    { objectId : String
    , createdAt : Date
    , updatedAt : Date
    , username : String
    }


userQuery : Parse.Query.Query
userQuery =
    Parse.Query.defaultQuery
        |> \defaultQuery ->
            { defaultQuery
                | className = Just "_User"
            }


decodeUser : Decoder User
decodeUser =
    Json.decode User
        |> Json.required "objectId" Json.string
        |> Json.required "createdAt" decodeDate
        |> Json.required "updatedAt" decodeDate
        |> Json.required "username" Json.string


decodeDate : Decoder Date
decodeDate =
    Json.string
        |> Json.andThen
            (\string ->
                Date.fromString string
                    |> Result.toMaybe
                    |> Maybe.map Json.succeed
                    |> Maybe.withDefault (Json.fail ("unknown Date `" ++ string ++ "'"))
            )


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.table []
            [ Html.thead []
                [ Html.tr []
                    [ Html.th [] [ text "objectId" ]
                    , Html.th [] [ text "createdAt" ]
                    , Html.th [] [ text "updatedAt" ]
                    , Html.th [] [ text "username" ]
                    ]
                ]
            , Html.tbody []
                (List.map
                    (\user ->
                        Html.tr []
                            [ Html.td [] [ text user.objectId ]
                            , Html.td [] [ text (toString user.createdAt) ]
                            , Html.td [] [ text (toString user.updatedAt) ]
                            , Html.td [] [ text user.username ]
                            ]
                    )
                    (Dict.values model.users)
                )
            ]
        , Html.pre
            []
            [ model.userEvents
                |> List.map toString
                |> String.join "\n"
                |> text
            ]
        ]
