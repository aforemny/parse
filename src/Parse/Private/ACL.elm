module Parse.Private.ACL exposing
    ( ACL
    , Permissions
    , RoleName
    , acl
    , anybody
    , decode
    , encode
    , extended
    , roles
    , simple
    , users
    )

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Parse.Private.ObjectId as ObjectId exposing (ObjectId)
import Parse.Private.Pointer as Pointer exposing (Pointer, pointer)


type ACL user
    = ACL
        { anybody : Permissions
        , roles : List ( RoleName, Permissions )
        , users : List ( Pointer user, Permissions )
        }


type alias RoleName =
    String


acl :
    { anybody : Permissions
    , roles : List ( RoleName, Permissions )
    , users : List ( Pointer user, Permissions )
    }
    -> ACL user
acl acl_ =
    ACL acl_


anybody : ACL user -> Permissions
anybody (ACL acl_) =
    acl_.anybody


roles : ACL user -> List ( RoleName, Permissions )
roles (ACL acl_) =
    acl_.roles


users : ACL user -> List ( Pointer user, Permissions )
users (ACL acl_) =
    acl_.users


encode : ACL user -> Value
encode acl_ =
    Encode.object
        (List.concat
            [ [ ( "*", encodePermissions (anybody acl_) )
              ]
            , roles acl_
                |> List.map
                    (\( roleName, permissions ) ->
                        ( "role:" ++ roleName
                        , encodePermissions permissions
                        )
                    )
            , users acl_
                |> List.map
                    (\( pointer, permissions ) ->
                        ( ObjectId.toString (Pointer.objectId pointer)
                        , encodePermissions permissions
                        )
                    )
            ]
        )


decode : Decoder (ACL user)
decode =
    Decode.keyValuePairs permissionsDecoder
        |> Decode.map
            (List.foldl
                (\( key, permissions ) result ->
                    if key == "*" then
                        { result
                            | anybody = ( "*", permissions ) :: result.roles
                        }

                    else if String.startsWith "role:" key then
                        let
                            roleName =
                                String.dropLeft 5 key
                        in
                        { result
                            | roles = ( roleName, permissions ) :: result.roles
                        }

                    else
                        let
                            user =
                                pointer "_User" (ObjectId.fromString key)
                        in
                        { result
                            | users = ( user, permissions ) :: result.users
                        }
                )
                { anybody = []
                , roles = []
                , users = []
                }
            )
        |> Decode.map
            (\acl_ ->
                ACL
                    { anybody =
                        acl_.anybody
                            |> List.head
                            |> Maybe.map Tuple.second
                            |> Maybe.withDefault (simple { read = False, write = False })
                    , roles = acl_.roles
                    , users = acl_.users
                    }
            )


type alias Permissions =
    { get : Bool
    , find : Bool
    , write : Bool
    , update : Bool
    , delete : Bool
    , addFields : Bool
    }


simple : { read : Bool, write : Bool } -> Permissions
simple { read, write } =
    { get = read
    , find = read
    , write = write
    , update = write
    , delete = write
    , addFields = False
    }


extended :
    { get : Bool
    , find : Bool
    , write : Bool
    , update : Bool
    , delete : Bool
    , addFields : Bool
    }
    -> Permissions
extended { get, find, write, update, delete, addFields } =
    { get = get
    , find = find
    , write = write
    , update = update
    , delete = delete
    , addFields = addFields
    }


encodePermissions : Permissions -> Value
encodePermissions perms =
    Encode.object
        [ ( "get", Encode.bool perms.get )
        , ( "find", Encode.bool perms.find )
        , ( "write", Encode.bool perms.write )
        , ( "update", Encode.bool perms.update )
        , ( "delete", Encode.bool perms.delete )
        , ( "addFields", Encode.bool perms.addFields )
        ]


permissionsDecoder : Decoder Permissions
permissionsDecoder =
    Decode.map6
        (\get find write update delete addFields ->
            { get = get
            , find = find
            , write = write
            , update = update
            , delete = delete
            , addFields = addFields
            }
        )
        (Decode.oneOf
            [ Decode.at [ "get" ] Decode.bool
            , Decode.at [ "read" ] Decode.bool
            , Decode.succeed False
            ]
        )
        (Decode.oneOf
            [ Decode.at [ "find" ] Decode.bool
            , Decode.at [ "read" ] Decode.bool
            , Decode.succeed False
            ]
        )
        (Decode.oneOf
            [ Decode.at [ "write" ] Decode.bool

            -- TODO: not right?
            , Decode.succeed False
            ]
        )
        (Decode.oneOf
            [ Decode.at [ "update" ] Decode.bool
            , Decode.at [ "write" ] Decode.bool
            , Decode.succeed False
            ]
        )
        (Decode.oneOf
            [ Decode.at [ "delete" ] Decode.bool
            , Decode.at [ "write" ] Decode.bool
            , Decode.succeed False
            ]
        )
        (Decode.oneOf
            [ Decode.at [ "addFields" ] Decode.bool
            , Decode.succeed False
            ]
        )
