module Parse exposing
    ( Config, simpleConfig
    , SessionToken
    , Request
    , send
    , toTask
    , create, get, update, delete
    , Object
    , ObjectId
    , Pointer
    , pointer
    , query, Query, emptyQuery, encodeQuery
    , Constraint
    , and, or, exists
    , equalTo, notEqualTo, regex
    , lessThan, lessThanOrEqualTo, greaterThan, greaterThanOrEqualTo
    , signUp
    , logIn
    , emailVerificationRequest, passwordResetRequest
    , getUser, getCurrentUser, updateUser, deleteUser
    , Session
    , createSession
    , getSession
    , updateSession
    , getSessions
    , deleteSession
    , CreatedWith
    , Action
    , AuthProvider
    , Error, Cause, code
    , ACL
    , RoleName
    , acl
    , anybody, users, roles
    , Permissions
    , simple
    , extended
    , Role
    , createRole
    , getRole
    , deleteRole
    , addUsers
    , deleteUsers
    , addRoles
    , deleteRoles
    , File
    , name
    , url
    , encodeFile
    , fileDecoder
    , ContentType
    , uploadFile
    , deleteFile
    , GeoPoint
    , geoPoint
    , latitude
    , longitude
    , getConfig
    , updateConfig
    , Event
    , post
    , postAt
    , function
    , job
    )

{-|


# Configuration

@docs Config, simpleConfig

@docs SessionToken


# Getting started

@docs Request
@docs send
@docs toTask


# Objects

@docs create, get, update, delete

@docs Object
@docs ObjectId


# Pointers

@docs Pointer
@docs pointer


# Queries

@docs query, Query, emptyQuery, encodeQuery


## Constraints

@docs Constraint

@docs and, or, exists

@docs equalTo, notEqualTo, regex

@docs lessThan, lessThanOrEqualTo, greaterThan, greaterThanOrEqualTo


# Users

@docs signUp

@docs logIn

@docs emailVerificationRequest, passwordResetRequest

@docs getUser, getCurrentUser, updateUser, deleteUser


# Sessions

@docs Session
@docs createSession
@docs getSession
@docs updateSession
@docs getSessions
@docs deleteSession
@docs CreatedWith
@docs Action
@docs AuthProvider


# Errors

@docs Error, Cause, code


# ACL

@docs ACL
@docs RoleName
@docs acl
@docs anybody, users, roles


## Permissions

@docs Permissions
@docs simple
@docs extended


# Roles

@docs Role
@docs createRole
@docs getRole
@docs deleteRole


## Updating roles

@docs addUsers
@docs deleteUsers
@docs addRoles
@docs deleteRoles


# Files

@docs File
@docs name
@docs url
@docs encodeFile
@docs fileDecoder
@docs ContentType
@docs uploadFile
@docs deleteFile


# GeoPoints

@docs GeoPoint
@docs geoPoint
@docs latitude
@docs longitude


# Config

@docs getConfig
@docs updateConfig


# Analytics

@docs Event
@docs post
@docs postAt


# Cloud code

@docs function
@docs job

-}

import Dict
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Parse.Decode as Decode
import Parse.Private.ACL
import Parse.Private.Analytics
import Parse.Private.CloudCode
import Parse.Private.Config
import Parse.Private.Error
import Parse.Private.File
import Parse.Private.GeoPoint
import Parse.Private.Object
import Parse.Private.ObjectId
import Parse.Private.Pointer
import Parse.Private.Query
import Parse.Private.Request
import Parse.Private.Role
import Parse.Private.Session
import Parse.Private.SessionToken
import Parse.Private.User
import Task exposing (Task)
import Time exposing (Posix)



---- CONFIG


{-| TODO
-}
type alias Config =
    Parse.Private.Request.Config


{-| TODO
-}
simpleConfig : String -> String -> Config
simpleConfig =
    Parse.Private.Request.simpleConfig


{-| TODO
-}
type alias SessionToken =
    Parse.Private.SessionToken.SessionToken



---- OBJECTS


{-| TODO
-}
type alias ObjectId a =
    Parse.Private.ObjectId.ObjectId a


{-| TODO
-}
type alias Object a =
    Parse.Private.Object.Object a


{-| TODO
-}
create :
    String
    -> (a -> Value)
    -> a
    -> Request { objectId : ObjectId a, createdAt : Posix }
create =
    Parse.Private.Object.create


{-| TODO
-}
get : String -> Decoder (Object a) -> ObjectId a -> Request (Object a)
get =
    Parse.Private.Object.get


{-| The type of `update` is more general to facilitate delta updates. Usually when
doing full updates its type signature is

    update : String -> (a -> Value) -> ObjectId a -> a -> Request { updatedAt : Posix }

-}
update : String -> (b -> Value) -> ObjectId a -> b -> Request { updatedAt : Posix }
update =
    Parse.Private.Object.update


{-| TODO
-}
delete : String -> ObjectId a -> Request {}
delete =
    Parse.Private.Object.delete



-- POINTERS


{-| TODO
-}
type alias Pointer a =
    Parse.Private.Pointer.Pointer a


{-| TODO
-}
pointer : String -> ObjectId a -> Pointer a
pointer =
    Parse.Private.Pointer.pointer



-- QUERY


{-| TODO
-}
type alias Query =
    Parse.Private.Query.Query


{-| TODO

@todo(aforemny) type Query a, query : Query a -> Request (List a)

-}
query : Decoder (Object a) -> Query -> Request (List (Object a))
query =
    Parse.Private.Query.query


{-| TODO
-}
emptyQuery : String -> Query
emptyQuery =
    Parse.Private.Query.emptyQuery


{-| TODO
-}
regex : String -> String -> Constraint
regex =
    Parse.Private.Query.regex


{-| TODO
-}
type alias Constraint =
    Parse.Private.Query.Constraint


{-| TODO
-}
or : List Constraint -> Constraint
or =
    Parse.Private.Query.or


{-| TODO
-}
and : List Constraint -> Constraint
and =
    Parse.Private.Query.and


{-| TODO
-}
notEqualTo : String -> Value -> Constraint
notEqualTo =
    Parse.Private.Query.notEqualTo


{-| TODO

@todo(aforemny) lessThanOrEqualTo : String -> Value -> Constraint

-}
lessThanOrEqualTo : String -> Float -> Constraint
lessThanOrEqualTo =
    Parse.Private.Query.lessThanOrEqualTo


{-| TODO

@todo(aforemny) lessThan : String -> Value -> Constraint

-}
lessThan : String -> Float -> Constraint
lessThan =
    Parse.Private.Query.lessThan


{-| TODO

@todo(aforemny) greaterThanOrEqualTo : String -> Value -> Constraint

-}
greaterThanOrEqualTo : String -> Float -> Constraint
greaterThanOrEqualTo =
    Parse.Private.Query.greaterThanOrEqualTo


{-| TODO

@todo(aforemny) greaterThan : String -> Value -> Constraint

-}
greaterThan : String -> Float -> Constraint
greaterThan =
    Parse.Private.Query.greaterThan


{-| TODO
-}
exists : String -> Constraint
exists =
    Parse.Private.Query.exists


{-| TODO
-}
equalTo : String -> Value -> Constraint
equalTo =
    Parse.Private.Query.equalTo


{-| TODO
-}
encodeQuery : Query -> Value
encodeQuery =
    Parse.Private.Query.encodeQuery



-- USER


{-| TODO
-}
updateUser : (user -> Value) -> ObjectId user -> user -> Request { updatedAt : Posix }
updateUser =
    Parse.Private.User.updateUser


{-| TODO

@todo(aforemny) signUp : (user -> Value) -> { user | username : String, password : String } -> Request { objectId : ObjectId user, createdAt : Posix, sessionToken : SessionToken }

-}
signUp :
    (user -> List ( String, Value ))
    -> String
    -> String
    -> user
    -> Request { objectId : ObjectId user, createdAt : Posix, sessionToken : SessionToken }
signUp =
    Parse.Private.User.signUp


{-| TODO
-}
logIn :
    Decoder (Object a)
    -> String
    -> String
    -> Request { user : Object a, sessionToken : SessionToken }
logIn =
    Parse.Private.User.logIn


{-| TODO
-}
passwordResetRequest : String -> Request {}
passwordResetRequest =
    Parse.Private.User.passwordResetRequest


{-| TODO
-}
emailVerificationRequest : String -> Request {}
emailVerificationRequest =
    Parse.Private.User.emailVerificationRequest


{-| TODO
-}
deleteUser : ObjectId a -> Request {}
deleteUser =
    Parse.Private.User.deleteUser


{-| TODO
-}
getUser : Decoder (Object a) -> ObjectId a -> Request (Object a)
getUser =
    Parse.Private.User.getUser


{-| TODO
-}
getCurrentUser : Decoder (Object a) -> Request (Object a)
getCurrentUser =
    Parse.Private.User.getCurrentUser



-- SESSIONS


{-| TODO
-}
type alias Session user =
    Parse.Private.Session.Session user


{-| TODO
-}
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
createSession =
    Parse.Private.Session.createSession


{-| TODO
-}
getSession : ObjectId (Session user) -> Request (Object (Session user))
getSession =
    Parse.Private.Session.getSession


{-| TODO
-}
updateSession : (b -> Value) -> ObjectId a -> b -> Request { updatedAt : Posix }
updateSession =
    Parse.Private.Session.updateSession


{-| TODO
-}
getSessions : Request (List (Object (Session user)))
getSessions =
    Parse.Private.Session.getSessions


{-| TODO
-}
deleteSession : ObjectId (Session user) -> Request {}
deleteSession =
    Parse.Private.Session.deleteSession


{-| TODO
-}
type alias CreatedWith =
    Parse.Private.Session.CreatedWith


{-| TODO
-}
type alias Action =
    Parse.Private.Session.Action


{-| TODO
-}
type alias AuthProvider =
    Parse.Private.Session.AuthProvider



-- ROLES


{-| TODO
-}
type alias ACL user =
    Parse.Private.ACL.ACL user


{-| TODO
-}
type alias RoleName =
    Parse.Private.ACL.RoleName


{-| TODO
-}
acl :
    { anybody : Permissions
    , users : List ( Pointer user, Permissions )
    , roles : List ( RoleName, Permissions )
    }
    -> ACL user
acl =
    Parse.Private.ACL.acl


{-| TODO
-}
anybody : ACL user -> Permissions
anybody =
    Parse.Private.ACL.anybody


{-| TODO
-}
users : ACL user -> List ( Pointer user, Permissions )
users =
    Parse.Private.ACL.users


{-| TODO
-}
roles : ACL user -> List ( RoleName, Permissions )
roles =
    Parse.Private.ACL.roles


{-| TODO
-}
type alias Permissions =
    Parse.Private.ACL.Permissions


{-| TODO
-}
simple : { read : Bool, write : Bool } -> Permissions
simple =
    Parse.Private.ACL.simple


{-| TODO
-}
extended :
    { get : Bool
    , find : Bool
    , write : Bool
    , update : Bool
    , delete : Bool
    , addFields : Bool
    }
    -> Permissions
extended =
    Parse.Private.ACL.extended


{-| TODO
-}
type alias Role user =
    Parse.Private.Role.Role user


{-| TODO
-}
role =
    Parse.Private.Role.role


{-| TODO
-}
createRole :
    Role user
    -> List (Pointer user)
    -> List (Pointer (Role user))
    -> Request { objectId : ObjectId (Role user), createdAt : Posix }
createRole =
    Parse.Private.Role.createRole


{-| TODO
-}
getRole : ObjectId (Role user) -> Request (Object (Role user))
getRole =
    Parse.Private.Role.getRole


{-| TODO
-}
addUsers : ObjectId (Role user) -> List (Pointer user) -> Request { updatedAt : Posix }
addUsers =
    Parse.Private.Role.addUsers


{-| TODO
-}
deleteUsers : ObjectId (Role user) -> List (Pointer user) -> Request { updatedAt : Posix }
deleteUsers =
    Parse.Private.Role.addUsers


{-| TODO
-}
addRoles :
    ObjectId (Role user)
    -> List (Pointer (Role user))
    -> Request { updatedAt : Posix }
addRoles =
    Parse.Private.Role.addRoles


{-| TODO
-}
deleteRoles :
    ObjectId (Role user)
    -> List (Pointer (Role user))
    -> Request { updatedAt : Posix }
deleteRoles =
    Parse.Private.Role.addRoles


{-| TODO
-}
deleteRole : ObjectId (Role user) -> Request {}
deleteRole =
    Parse.Private.Role.deleteRole



-- ERROR


{-| TODO
-}
type alias Error =
    Parse.Private.Error.Error


{-| TODO
-}
type alias Cause =
    Parse.Private.Error.Cause


{-| TODO
-}
code : Cause -> Int
code =
    Parse.Private.Error.code



-- REQUEST


{-| TODO
-}
type alias Request a =
    Parse.Private.Request.Request a


{-| TODO
-}
toTask : Config -> Request a -> Task Error a
toTask =
    Parse.Private.Request.toTask


{-| TODO
-}
send : Config -> (Result Error a -> m) -> Request a -> Cmd m
send =
    Parse.Private.Request.send



-- FILES


{-| TODO
-}
type alias File =
    Parse.Private.File.File


{-| TODO
-}
name : File -> String
name =
    Parse.Private.File.name


{-| TODO
-}
url : File -> String
url =
    Parse.Private.File.url


{-| TODO
-}
encodeFile : File -> Value
encodeFile =
    Parse.Private.File.encodeFile


{-| TODO
-}
fileDecoder : Decoder File
fileDecoder =
    Parse.Private.File.fileDecoder


{-| TODO
-}
type alias ContentType =
    Parse.Private.File.ContentType


{-| TODO
-}
uploadFile : String -> ContentType -> Value -> Request File
uploadFile =
    Parse.Private.File.uploadFile


{-| TODO
-}
deleteFile : File -> Request {}
deleteFile =
    Parse.Private.File.deleteFile



-- GEOPOINTS


{-| TODO
-}
type alias GeoPoint =
    Parse.Private.GeoPoint.GeoPoint


{-| TODO
-}
geoPoint : { latitude : Float, longitude : Float } -> GeoPoint
geoPoint =
    Parse.Private.GeoPoint.geoPoint


{-| TODO
-}
latitude : GeoPoint -> Float
latitude =
    Parse.Private.GeoPoint.latitude


{-| TODO
-}
longitude : GeoPoint -> Float
longitude =
    Parse.Private.GeoPoint.longitude



-- CONFIG


{-| TODO
-}
getConfig : Decoder a -> Request a
getConfig =
    Parse.Private.Config.getConfig


{-| TODO
-}
updateConfig : List ( String, Value ) -> Request Bool
updateConfig =
    Parse.Private.Config.updateConfig



-- ANALYTICS


{-| TODO
-}
type alias Event a =
    Parse.Private.Analytics.Event a


{-| TODO
-}
post : (Event a -> List ( String, Value )) -> Event a -> Request {}
post =
    Parse.Private.Analytics.post


{-| TODO
-}
postAt : (Event a -> List ( String, Value )) -> Posix -> Event a -> Request {}
postAt =
    Parse.Private.Analytics.postAt



-- CLOUD CODE


{-| TODO
-}
function : String -> Decoder a -> Value -> Request a
function =
    Parse.Private.CloudCode.function


{-| TODO
-}
job : String -> Value -> Request {}
job =
    Parse.Private.CloudCode.job
