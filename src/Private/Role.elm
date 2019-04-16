module Private.Role exposing
    ( Role
    , addRoles
    , addUsers
    , createRole
    , deleteRole
    , deleteRoles
    , deleteUsers
    , getRole
    , role
    )

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Parse.Decode as Decode
import Parse.Encode as Encode
import Private.ACL as ACL exposing (ACL)
import Private.Object exposing (Object)
import Private.ObjectId as ObjectId exposing (ObjectId)
import Private.Pointer as Pointer exposing (Pointer)
import Private.Request as Request exposing (Request, request)
import Time exposing (Posix)


type alias Role user =
    { name : String
    , acl : ACL user
    }


role :
    { name : String
    , acl : ACL user
    }
    -> Role user
role =
    identity


encode : Role user -> Value
encode { name, acl } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "acl", ACL.encode acl )
        ]


decode : Decoder (Object (Role user))
decode =
    Decode.succeed
        (\objectId createdAt updatedAt name acl ->
            { objectId = objectId
            , createdAt = createdAt
            , updatedAt = updatedAt
            , name = name
            , acl = acl
            }
        )
        |> Decode.required "objectId" Decode.objectId
        |> Decode.required "createdAt" Decode.date
        |> Decode.required "updatedAt" Decode.date
        |> Decode.required "name" Decode.string
        |> Decode.required "ACL" ACL.decode


createRole :
    Role user
    -> List (Pointer user)
    -> List (Pointer (Role user))
    -> Request { objectId : ObjectId (Role a), createdAt : Posix }
createRole { name, acl } users roles =
    let
        body =
            Encode.object
                [ ( "name", Encode.string name )
                , ( "acl", ACL.encode acl )
                , ( "users"
                  , users
                        |> List.map Encode.pointer
                        |> (\objects ->
                                Encode.object
                                    [ ( "__op", Encode.string "AddRelation" )
                                    , ( "objects", Encode.list identity objects )
                                    ]
                           )
                  )
                , ( "roles"
                  , roles
                        |> List.map Encode.pointer
                        |> (\objects ->
                                Encode.object
                                    [ ( "__op", Encode.string "AddRelation" )
                                    , ( "objects", Encode.list identity objects )
                                    ]
                           )
                  )
                ]
    in
    request
        { method = "POST"
        , endpoint = "/roles"
        , body = Just body
        , decoder = Request.postDecoder
        }


getRole : ObjectId (Role user) -> Request (Object (Role user))
getRole objectId =
    request
        { method = "GET"
        , endpoint = "/roles/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = decode
        }


deleteRole : ObjectId (Role user) -> Request {}
deleteRole objectId =
    request
        { method = "DELETE"
        , endpoint = "/roles/" ++ ObjectId.toString objectId
        , body = Nothing
        , decoder = Decode.succeed {}
        }


addUsers : ObjectId (Role user) -> List (Pointer user) -> Request { updatedAt : Posix }
addUsers objectId users =
    request
        { method = "PUT"
        , endpoint = "/roles/" ++ ObjectId.toString objectId
        , body = Just (Encode.object [ ( "users", addRelation users ) ])
        , decoder = Request.putDecoder
        }


deleteUsers : ObjectId (Role user) -> List (Pointer user) -> Request { updatedAt : Posix }
deleteUsers objectId users =
    request
        { method = "PUT"
        , endpoint = "/roles/" ++ ObjectId.toString objectId
        , body = Just (Encode.object [ ( "users", removeRelation users ) ])
        , decoder = Request.putDecoder
        }


addRoles :
    ObjectId (Role user)
    -> List (Pointer (Role user))
    -> Request { updatedAt : Posix }
addRoles objectId roles =
    request
        { method = "PUT"
        , endpoint = "/roles/" ++ ObjectId.toString objectId
        , body = Just (Encode.object [ ( "roles", addRelation roles ) ])
        , decoder = Request.putDecoder
        }


deleteRoles :
    ObjectId (Role user)
    -> List (Pointer (Role user))
    -> Request { updatedAt : Posix }
deleteRoles objectId roles =
    request
        { method = "PUT"
        , endpoint = "/roles/" ++ ObjectId.toString objectId
        , body = Just (Encode.object [ ( "roles", removeRelation roles ) ])
        , decoder = Request.putDecoder
        }


{-| TODO: move to Pointer
-}
addRelation : List (Pointer a) -> Value
addRelation pointers =
    Encode.object
        [ ( "__op", Encode.string "AddRelation" )
        , ( "objects", Encode.list Encode.pointer pointers )
        ]


{-| TODO: move to Pointer
-}
removeRelation : List (Pointer a) -> Value
removeRelation pointers =
    Encode.object
        [ ( "__op", Encode.string "RemoveRelation" )
        , ( "objects", Encode.list Encode.pointer pointers )
        ]
