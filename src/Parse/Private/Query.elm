module Parse.Private.Query exposing
    ( Constraint(..)
    , FieldConstraint(..)
    , Query
    , and
    , emptyQuery
    , encodeConstraint
    , encodeConstraintHelp
    , encodeFieldConstraint
    , encodeQuery
    , equalTo
    , exists
    , greaterThan
    , greaterThanOrEqualTo
    , lessThan
    , lessThanOrEqualTo
    , notEqualTo
    , or
    , query
    , regex
    , serializeQuery
    )

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Parse.Private.Error exposing (Error)
import Parse.Private.Object exposing (Object)
import Parse.Private.Request as Requet exposing (Request, request)
import Task exposing (Task)
import Url


query :
    Decoder (Object a)
    -> Query
    -> Request (List (Object a))
query objectDecoder query_ =
    request
        { method = "GET"
        , endpoint = "/classes/" ++ query_.className ++ "?" ++ serializeQuery query_
        , body = Nothing
        , decoder = Decode.field "results" (Decode.list objectDecoder)
        }


type alias Query =
    { className : String
    , whereClause :
        Constraint

    -- RESPONSE
    , order : List String
    , keys : List String
    , include : List String
    , count :
        Bool

    -- PAGINATION
    , limit : Maybe Int
    , skip : Maybe Int
    }


emptyQuery : String -> Query
emptyQuery className =
    { className = className
    , whereClause = And []
    , order = []
    , keys = []
    , include = []
    , count = False
    , limit = Nothing
    , skip = Nothing
    }


encodeQuery : Query -> Value
encodeQuery query_ =
    let
        required key value =
            Just ( key, value )

        optional key encode value =
            Maybe.map (\value_ -> ( key, encode value_ )) value
    in
    [ required "className" (Encode.string query_.className)
    , required "where" (encodeConstraint query_.whereClause)
    , if query_.include == [] then
        Nothing

      else
        required "include" (Encode.string (String.join "," query_.include))
    , if query_.count then
        required "count" (Encode.int 1)

      else
        Nothing
    , if query_.keys == [] then
        Nothing

      else
        required "keys" (Encode.string (String.join "," query_.keys))
    , optional "limit" Encode.int query_.limit
    , query_.skip
        |> Maybe.andThen
            (\skip ->
                if skip <= 0 then
                    Nothing

                else
                    required "skip" (Encode.int skip)
            )
    , if query_.order == [] then
        Nothing

      else
        required "order" (Encode.string (String.join "," query_.order))
    ]
        |> List.filterMap identity
        |> Encode.object


type Constraint
    = And (List Constraint)
    | Or (List Constraint)
    | Field String (List FieldConstraint)


type FieldConstraint
    = Exists
    | EqualTo Value
    | NotEqualTo Value
    | LessThan Float
    | LessThanOrEqualTo Float
    | GreaterThan Float
    | GreaterThanOrEqualTo Float
    | Regex String



{- TODO: missing constraints:

   $in          Contained In
   $nin         Not Contained in
   $select      This matches a value for a key in the result of a different query
   $dontSelect  Requires that a key’s value not match a value for a key in the result of a different query
   $all         Contains all of the given values
   $text        Performs a full text search on indexed fields
-}


and : List Constraint -> Constraint
and constraints =
    let
        flattenNestedAnds constraint flatConstraints =
            case constraint of
                And nestedConstraints ->
                    nestedConstraints ++ flatConstraints

                _ ->
                    constraint :: flatConstraints

        mergeFieldConstraints constraint ( fieldConstraints, otherConstraints ) =
            case constraint of
                Field fieldName actualFieldConstraints ->
                    ( Dict.update fieldName
                        (\maybeActualFieldConstraints ->
                            case maybeActualFieldConstraints of
                                Just otherActualFieldConstraints ->
                                    Just <|
                                        actualFieldConstraints
                                            ++ otherActualFieldConstraints

                                Nothing ->
                                    Just actualFieldConstraints
                        )
                        fieldConstraints
                    , otherConstraints
                    )

                _ ->
                    ( fieldConstraints
                    , constraint :: otherConstraints
                    )
    in
    constraints
        |> List.foldr flattenNestedAnds []
        |> List.foldr mergeFieldConstraints ( Dict.empty, [] )
        |> Tuple.mapFirst
            (\fieldConstraints ->
                fieldConstraints
                    |> Dict.foldl
                        (\fieldName actualFieldConstraints result ->
                            Field fieldName actualFieldConstraints
                                :: result
                        )
                        []
            )
        |> (\( fieldConstraints, otherConstraints ) ->
                fieldConstraints ++ otherConstraints
           )
        |> And


or : List Constraint -> Constraint
or =
    Or


exists : String -> Constraint
exists fieldName =
    Field fieldName [ Exists ]


equalTo : String -> Value -> Constraint
equalTo fieldName =
    Field fieldName << List.singleton << EqualTo


notEqualTo : String -> Value -> Constraint
notEqualTo fieldName =
    Field fieldName << List.singleton << NotEqualTo


lessThan : String -> Float -> Constraint
lessThan fieldName =
    Field fieldName << List.singleton << LessThan


lessThanOrEqualTo : String -> Float -> Constraint
lessThanOrEqualTo fieldName =
    Field fieldName << List.singleton << LessThanOrEqualTo


greaterThan : String -> Float -> Constraint
greaterThan fieldName =
    Field fieldName << List.singleton << GreaterThan


greaterThanOrEqualTo : String -> Float -> Constraint
greaterThanOrEqualTo fieldName =
    Field fieldName << List.singleton << GreaterThanOrEqualTo


regex : String -> String -> Constraint
regex fieldName =
    Field fieldName << List.singleton << Regex



-- INTERNAL HELPER


serializeQuery : Query -> String
serializeQuery query_ =
    [ [ "where="
      , encodeConstraint query_.whereClause
            |> Encode.encode 0
            |> Url.percentEncode
      ]
        |> String.concat
        |> Just
    , if List.isEmpty query_.order then
        Nothing

      else
        Just (String.join "," query_.order)
    , if List.isEmpty query_.keys then
        Nothing

      else
        Just (String.join "," query_.keys)
    , if List.isEmpty query_.include then
        Nothing

      else
        Just ("include=" ++ String.join "," query_.include)
    , if query_.count then
        Just "count=1"

      else
        Nothing
    , query_.limit
        |> Maybe.map (\limit -> "limit=" ++ String.fromInt limit)
    , query_.skip
        |> Maybe.map (\skip -> "skip=" ++ String.fromInt skip)
    ]
        |> List.filterMap identity
        |> String.join "&"


encodeConstraint : Constraint -> Value
encodeConstraint constraint =
    constraint
        |> encodeConstraintHelp
        |> Encode.object


encodeConstraintHelp : Constraint -> List ( String, Value )
encodeConstraintHelp constraint =
    case constraint of
        And constraints ->
            constraints
                |> List.map encodeConstraintHelp
                |> List.concat

        Or constraints ->
            [ ( "$or"
              , Encode.list (encodeConstraintHelp >> Encode.object) constraints
              )
            ]

        Field fieldName fieldConstraints ->
            let
                fieldEqualTo =
                    fieldConstraints
                        |> List.filterMap
                            (\constraint_ ->
                                case constraint_ of
                                    EqualTo value ->
                                        Just value

                                    _ ->
                                        Nothing
                            )
                        |> List.head
            in
            [ ( fieldName
              , case fieldEqualTo of
                    Just value ->
                        value

                    Nothing ->
                        fieldConstraints
                            |> List.filterMap encodeFieldConstraint
                            |> Encode.object
              )
            ]


encodeFieldConstraint : FieldConstraint -> Maybe ( String, Value )
encodeFieldConstraint fieldConstraint =
    case fieldConstraint of
        Exists ->
            Just
                ( "$exists", Encode.bool True )

        NotEqualTo value ->
            Just
                ( "$ne", value )

        Regex regex_ ->
            Just
                ( "$regex", Encode.string regex_ )

        LessThan float ->
            Just
                ( "$lt", Encode.float float )

        LessThanOrEqualTo float ->
            Just
                ( "$lte", Encode.float float )

        GreaterThan float ->
            Just
                ( "$gt", Encode.float float )

        GreaterThanOrEqualTo float ->
            Just
                ( "$gte", Encode.float float )

        EqualTo _ ->
            Nothing
