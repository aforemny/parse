module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode exposing (Value)
import Parse exposing (Error, Object, ObjectId, Query)
import Parse.Decode as Parse
import Task exposing (Task)
import Time exposing (Posix)


main : Program {} Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { title : String
    , description : String
    , events : List (Object Event)
    , titleQuery : String
    , descriptionQuery : String
    }


type Msg
    = TitleUpdated String
    | DescriptionUpdated String
    | FormSubmitted
    | EventCreated { createdAt : Posix, objectId : ObjectId Event }
    | EventCreateFailed Error
    | EventReceived (Object Event)
    | EventGetFailed Error
    | EventsReceived (List (Object Event))
    | EventGetAllFailed Error
    | DeleteEventClicked (ObjectId Event)
    | EventDeleted {}
    | EventDeleteFailed Error
      -- FILTER
    | FilterFormSubmitted
    | TitleQueryUpdated String
    | DescriptionQueryUpdated String


init : {} -> ( Model, Cmd Msg )
init flags =
    ( { title = ""
      , description = ""
      , events = []
      , titleQuery = ""
      , descriptionQuery = ""
      }
    , getAllEvents
        |> Task.attempt
            (\result ->
                case result of
                    Ok events ->
                        EventsReceived events

                    Err error ->
                        EventGetAllFailed error
            )
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TitleUpdated newTitle ->
            ( { model | title = newTitle }
            , Cmd.none
            )

        DescriptionUpdated newDescription ->
            ( { model | description = newDescription }
            , Cmd.none
            )

        FormSubmitted ->
            ( model
            , createEvent
                { title = model.title
                , description = model.description
                }
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok info ->
                                EventCreated info

                            Err error ->
                                EventCreateFailed error
                    )
            )

        EventCreated { createdAt, objectId } ->
            ( model
            , getEvent objectId
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok event ->
                                EventReceived event

                            Err error ->
                                EventGetFailed error
                    )
            )

        EventCreateFailed error ->
            ( model
            , Cmd.none
            )

        EventReceived event ->
            ( { model | events = event :: model.events }
            , Cmd.none
            )

        EventGetFailed error ->
            ( model
            , Cmd.none
            )

        EventsReceived events ->
            ( { model | events = events }
            , Cmd.none
            )

        EventGetAllFailed error ->
            ( model
            , Cmd.none
            )

        DeleteEventClicked objectId ->
            ( model
            , deleteEvent objectId
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok event ->
                                EventDeleted event

                            Err error ->
                                EventDeleteFailed error
                    )
            )

        EventDeleted _ ->
            ( model
            , getAllEvents
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok events ->
                                EventsReceived events

                            Err error ->
                                EventGetAllFailed error
                    )
            )

        EventDeleteFailed error ->
            ( model
            , Cmd.none
            )

        FilterFormSubmitted ->
            ( model
            , Parse.query
                eventDecoder
                { className = "Event"
                , whereClause =
                    Parse.and
                        [ Parse.regex "title" model.titleQuery
                        , Parse.exists "title"
                        , Parse.regex "description" model.descriptionQuery
                        ]
                , order = []
                , keys = []
                , include = []
                , count = False
                , limit = Nothing
                , skip = Nothing
                }
                |> Parse.toTask parseConfig
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok events ->
                                EventsReceived events

                            Err error ->
                                EventGetAllFailed error
                    )
            )

        TitleQueryUpdated newTitleQuery ->
            ( { model | titleQuery = newTitleQuery }
            , Cmd.none
            )

        DescriptionQueryUpdated newDescriptionQuery ->
            ( { model | descriptionQuery = newDescriptionQuery }
            , Cmd.none
            )


parseConfig : Parse.Config
parseConfig =
    { serverUrl = "http://localhost:1337/parse"
    , applicationId = "parse-example"
    , restAPIKey = Just "secret"
    , javascriptKey = Nothing
    , clientKey = Nothing
    , windowsKey = Nothing
    , masterKey = Nothing
    , sessionToken = Nothing
    }


type alias Event =
    { title : String
    , description : String
    }


createEvent :
    Event
    -> Task Error { createdAt : Posix, objectId : ObjectId Event }
createEvent event =
    Parse.toTask parseConfig <|
        Parse.create "Event" encodeEvent event


getEvent : ObjectId Event -> Task Error (Object Event)
getEvent objectId =
    Parse.toTask parseConfig <|
        Parse.get "Event" eventDecoder objectId


getAllEvents : Task Error (List (Object Event))
getAllEvents =
    Parse.toTask parseConfig <|
        Parse.query eventDecoder (Parse.emptyQuery "Event")


deleteEvent : ObjectId Event -> Task Error {}
deleteEvent objectId =
    Parse.toTask parseConfig <|
        Parse.delete "Event" objectId


encodeEvent : { title : String, description : String } -> Value
encodeEvent event =
    [ ( "title", Encode.string event.title )
    , ( "description", Encode.string event.description )
    ]
        |> Encode.object


eventDecoder : Decoder (Object Event)
eventDecoder =
    Decode.succeed
        (\objectId createdAt updatedAt title description ->
            { objectId = objectId
            , createdAt = createdAt
            , updatedAt = updatedAt
            , title = title
            , description = description
            }
        )
        |> Decode.required "objectId" Parse.objectId
        |> Decode.required "createdAt" Parse.date
        |> Decode.required "updatedAt" Parse.date
        |> Decode.required "title" Decode.string
        |> Decode.required "description" Decode.string


view : Model -> Html Msg
view model =
    Html.div
        []
        [ Html.ul [] <|
            List.map viewEvent model.events
        , Html.form
            [ Events.onSubmit FormSubmitted
            ]
            [ Html.label [] [ Html.text "Title" ]
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value model.title
                , Events.onInput TitleUpdated
                ]
                []
            , Html.label [] [ Html.text "Description" ]
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value model.description
                , Events.onInput DescriptionUpdated
                ]
                []
            , Html.button [] [ Html.text "Add" ]
            ]
        , Html.form
            [ Events.onSubmit FilterFormSubmitted ]
            [ Html.label [] [ Html.text "Title" ]
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value model.titleQuery
                , Events.onInput TitleQueryUpdated
                ]
                []
            , Html.label [] [ Html.text "Description" ]
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value model.descriptionQuery
                , Events.onInput DescriptionQueryUpdated
                ]
                []
            , Html.button [] [ Html.text "Filter" ]
            ]
        ]


viewEvent : Object Event -> Html Msg
viewEvent event =
    Html.li []
        [ Html.strong [] [ Html.text event.title ]
        , Html.text (": " ++ event.description)
        , Html.a
            [ Events.preventDefaultOn "click"
                (Decode.succeed ( DeleteEventClicked event.objectId, True ))
            , Attributes.href "#"
            ]
            [ Html.text "Delete" ]
        ]
