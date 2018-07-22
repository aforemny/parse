module Parse
    exposing
        ( Cause
        , Config
        , Constraint
        , Error
        , Object
        , ObjectId
        , Pointer
        , pointer
        , Query
        , SessionToken
        , and
        , code
        , create
        , delete
        , deleteUser
        , emailVerificationRequest
        , emptyQuery
        , encodeQuery
        , equalTo
        , exists
        , get
        , getCurrentUser
        , getUser
        , greaterThan
        , greaterThanOrEqualTo
        , lessThan
        , lessThanOrEqualTo
        , logIn
        , notEqualTo
        , or
        , passwordResetRequest
        , query
        , regex
        , signUp
        , simpleConfig
        , update
        , updateUser
        , Request
        , toTask
        , send
        , Role
        , createRole
        , getRole
        , addUsers
        , deleteUsers
        , addRoles
        , deleteRoles
        , deleteRole
        , ACL
        , RoleName
        , acl
        , anybody
        , users
        , roles
        , Permissions
        , simple
        , extended
        , function
        , job
        , Event
        , post
        , postAt
        , getConfig
        , updateConfig
        , GeoPoint
        , geoPoint
        , latitude
        , longitude
        , Session
        , createSession
        , getSession
        , updateSession
        , getSessions
        , deleteSession
        , CreatedWith
        , Action
        , AuthProvider
        , ContentType
        , File
        , name
        , url
        , encodeFile
        , fileDecoder
        , uploadFile
        , deleteFile
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

import Date exposing (Date)
import Dict
import Http exposing (Request)
import Private.ACL
import Private.Analytics
import Private.CloudCode
import Private.Config
import Private.Error
import Private.File
import Private.GeoPoint
import Private.Object
import Private.ObjectId
import Private.Pointer
import Private.Query
import Private.Request
import Private.Role
import Private.Role
import Private.Session
import Private.SessionToken
import Private.User
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Parse.Decode as Decode
import Task exposing (Task)


---- CONFIG


{-| TODO
-}
type alias Config =
    Private.Request.Config


{-| TODO
-}
simpleConfig : String -> String -> Config
simpleConfig =
    Private.Request.simpleConfig


{-| TODO
-}
type alias SessionToken =
    Private.SessionToken.SessionToken



---- OBJECTS


{-| TODO
-}
type alias ObjectId a =
    Private.ObjectId.ObjectId a


{-| TODO
-}
type alias Object a =
    Private.Object.Object a


{-| TODO
-}
create :
    String
    -> (a -> Value)
    -> a
    -> Request { objectId : ObjectId a, createdAt : Date }
create =
    Private.Object.create


{-| TODO
-}
get : String -> Decoder (Object a) -> ObjectId a -> Request (Object a)
get =
    Private.Object.get


{-|
The type of `update` is more general to facilitate delta updates. Usually when
doing full updates its type signature is

```elm
update : String -> (a -> Value) -> ObjectId a -> a -> Request { updatedAt : Date }
```
-}
update : String -> (b -> Value) -> ObjectId a -> b -> Request { updatedAt : Date }
update =
    Private.Object.update


{-| TODO
-}
delete : String -> ObjectId a -> Request {}
delete =
    Private.Object.delete



-- POINTERS


{-| TODO
-}
type alias Pointer a =
    Private.Pointer.Pointer a


{-| TODO
-}
pointer : String -> ObjectId a -> Pointer a
pointer =
    Private.Pointer.pointer



-- QUERY


{-| TODO
-}
type alias Query =
    Private.Query.Query


{-| TODO

@todo(aforemny) type Query a, query : Query a -> Request (List a)
-}
query : Decoder (Object a) -> Query -> Request (List (Object a))
query =
    Private.Query.query


{-| TODO
-}
emptyQuery : String -> Query
emptyQuery =
    Private.Query.emptyQuery


{-| TODO
-}
regex : String -> String -> Constraint
regex =
    Private.Query.regex


{-| TODO
-}
type alias Constraint =
    Private.Query.Constraint


{-| TODO
-}
or : List Constraint -> Constraint
or =
    Private.Query.or


{-| TODO
-}
and : List Constraint -> Constraint
and =
    Private.Query.and


{-| TODO

@todo(aforemny) notEqualTo : String -> Value -> Constraint
-}
notEqualTo : String -> String -> Constraint
notEqualTo =
    Private.Query.notEqualTo


{-| TODO

@todo(aforemny) lessThanOrEqualTo : String -> Value -> Constraint
-}
lessThanOrEqualTo : String -> Float -> Constraint
lessThanOrEqualTo =
    Private.Query.lessThanOrEqualTo


{-| TODO

@todo(aforemny) lessThan : String -> Value -> Constraint
-}
lessThan : String -> Float -> Constraint
lessThan =
    Private.Query.lessThan


{-| TODO

@todo(aforemny) greaterThanOrEqualTo : String -> Value -> Constraint
-}
greaterThanOrEqualTo : String -> Float -> Constraint
greaterThanOrEqualTo =
    Private.Query.greaterThanOrEqualTo


{-| TODO

@todo(aforemny) greaterThan : String -> Value -> Constraint
-}
greaterThan : String -> Float -> Constraint
greaterThan =
    Private.Query.greaterThan


{-| TODO
-}
exists : String -> Constraint
exists =
    Private.Query.exists


{-| TODO

@todo(aforemny) equalTo : String -> Value -> Constraint
-}
equalTo : String -> String -> Constraint
equalTo =
    Private.Query.equalTo


{-| TODO
-}
encodeQuery : Query -> Value
encodeQuery =
    Private.Query.encodeQuery



-- USER


{-| TODO
-}
updateUser : (user -> Value) -> ObjectId user -> user -> Request { updatedAt : Date }
updateUser =
    Private.User.updateUser


{-| TODO

@todo(aforemny) signUp : (user -> Value) -> { user | username : String, password : String } -> Request { objectId : ObjectId user, createdAt : Date, sessionToken : SessionToken }
-}
signUp :
    (user -> List ( String, Value ))
    -> String
    -> String
    -> user
    -> Request { objectId : ObjectId user, createdAt : Date, sessionToken : SessionToken }
signUp =
    Private.User.signUp


{-| TODO
-}
logIn :
    Decoder (Object a)
    -> String
    -> String
    -> Request { user : Object a, sessionToken : SessionToken }
logIn =
    Private.User.logIn


{-| TODO
-}
passwordResetRequest : String -> Request {}
passwordResetRequest =
    Private.User.passwordResetRequest


{-| TODO
-}
emailVerificationRequest : String -> Request {}
emailVerificationRequest =
    Private.User.emailVerificationRequest


{-| TODO
-}
deleteUser : ObjectId a -> Request {}
deleteUser =
    Private.User.deleteUser


{-| TODO
-}
getUser : Decoder (Object a) -> ObjectId a -> Request (Object a)
getUser =
    Private.User.getUser


{-| TODO
-}
getCurrentUser : Decoder (Object a) -> Request (Object a)
getCurrentUser =
    Private.User.getCurrentUser


-- SESSIONS



{-| TODO
-}
type alias Session user =
    Private.Session.Session user


{-| TODO
-}
createSession :
    Session user
    -> Request
        { createdAt : Date
        , createdWith : CreatedWith
        , objectId : ObjectId (Session user)
        , restricted : Bool
        , sessionToken : SessionToken
        }
createSession =
    Private.Session.createSession


{-| TODO
-}
getSession : ObjectId (Session user) -> Request (Object (Session user))
getSession =
    Private.Session.getSession


{-| TODO
-}
updateSession : (b -> Value) -> ObjectId a -> b -> Request { updatedAt : Date }
updateSession =
    Private.Session.updateSession


{-| TODO
-}
getSessions : Request (List (Object (Session user)))
getSessions =
    Private.Session.getSessions


{-| TODO
-}
deleteSession : ObjectId (Session user) -> Request {}
deleteSession =
    Private.Session.deleteSession


{-| TODO
-}
type alias CreatedWith =
    Private.Session.CreatedWith


{-| TODO
-}
type alias Action =
    Private.Session.Action


{-| TODO
-}
type alias AuthProvider =
    Private.Session.AuthProvider



-- ROLES


{-| TODO
-}
type alias ACL user =
    Private.ACL.ACL user


{-| TODO
-}
type alias RoleName =
    Private.ACL.RoleName


{-| TODO
-}
acl :
    { anybody : Permissions
    , users : List ( Pointer user, Permissions )
    , roles : List ( RoleName, Permissions )
    }
    -> ACL user
acl =
    Private.ACL.acl


{-| TODO
-}
anybody : ACL user -> Permissions
anybody =
    Private.ACL.anybody


{-| TODO
-}
users : ACL user -> List ( Pointer user, Permissions )
users =
    Private.ACL.users


{-| TODO
-}
roles : ACL user -> List ( RoleName, Permissions )
roles =
    Private.ACL.roles


{-| TODO
-}
type alias Permissions =
    Private.ACL.Permissions


{-| TODO
-}
simple : { read : Bool, write : Bool } -> Permissions
simple =
    Private.ACL.simple


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
    Private.ACL.extended


{-| TODO
-}
type alias Role user =
    Private.Role.Role user


{-| TODO
-}
role =
    Private.Role.role


{-| TODO
-}
createRole :
    Role user
    -> List (Pointer user)
    -> List (Pointer (Role user))
    -> Request { objectId : ObjectId (Role user), createdAt : Date }
createRole =
    Private.Role.createRole


{-| TODO
-}
getRole : ObjectId (Role user) -> Request (Object (Role user))
getRole =
    Private.Role.getRole


{-| TODO
-}
addUsers : ObjectId (Role user) -> List (Pointer user) -> Request { updatedAt : Date }
addUsers =
    Private.Role.addUsers


{-| TODO
-}
deleteUsers : ObjectId (Role user) -> List (Pointer user) -> Request { updatedAt : Date }
deleteUsers =
    Private.Role.addUsers


{-| TODO
-}
addRoles :
    ObjectId (Role user)
    -> List (Pointer (Role user))
    -> Request { updatedAt : Date }
addRoles =
    Private.Role.addRoles


{-| TODO
-}
deleteRoles :
    ObjectId (Role user)
    -> List (Pointer (Role user))
    -> Request { updatedAt : Date }
deleteRoles =
    Private.Role.addRoles


{-| TODO
-}
deleteRole : ObjectId (Role user) -> Request {}
deleteRole =
    Private.Role.deleteRole



-- ERROR


{-| TODO
-}
type alias Error =
    Private.Error.Error


{-| TODO
-}
type alias Cause =
    Private.Error.Cause


{-| TODO
-}
code : Cause -> Int
code =
    Private.Error.code



-- REQUEST


{-| TODO
-}
type alias Request a =
    Private.Request.Request a


{-| TODO
-}
toTask : Config -> Request a -> Task Error a
toTask =
    Private.Request.toTask


{-| TODO
-}
send : Config -> (Result Error a -> m) -> Request a -> Cmd m
send =
    Private.Request.send


-- FILES

{-| TODO
-}
type alias File =
    Private.File.File



{-| TODO
-}
name : File -> String
name =
    Private.File.name


{-| TODO
-}
url : File -> String
url =
    Private.File.url


{-| TODO
-}
encodeFile : File -> Value
encodeFile =
    Private.File.encodeFile


{-| TODO
-}
fileDecoder : Decoder File
fileDecoder =
    Private.File.fileDecoder


{-| TODO
-}
type alias ContentType =
    Private.File.ContentType


{-| TODO
-}
uploadFile : String -> ContentType -> Value -> Request File
uploadFile =
    Private.File.uploadFile


{-| TODO
-}
deleteFile : File -> Request {}
deleteFile =
    Private.File.deleteFile



-- GEOPOINTS


{-| TODO
-}
type alias GeoPoint =
    Private.GeoPoint.GeoPoint


{-| TODO
-}
geoPoint : { latitude : Float, longitude : Float } -> GeoPoint
geoPoint =
    Private.GeoPoint.geoPoint


{-| TODO
-}
latitude : GeoPoint -> Float
latitude =
    Private.GeoPoint.latitude


{-| TODO
-}
longitude : GeoPoint -> Float
longitude =
    Private.GeoPoint.longitude



-- CONFIG


{-| TODO
-}
getConfig : Decoder a -> Request a
getConfig =
    Private.Config.getConfig


{-| TODO
-}
updateConfig : List ( String, Value ) -> Request Bool
updateConfig =
    Private.Config.updateConfig



-- ANALYTICS


{-| TODO
-}
type alias Event a =
    Private.Analytics.Event a


{-| TODO
-}
post : (Event a -> List ( String, Value )) -> Event a -> Request {}
post =
    Private.Analytics.post


{-| TODO
-}
postAt : (Event a -> List ( String, Value )) -> Date -> Event a -> Request {}
postAt =
    Private.Analytics.postAt



-- CLOUD CODE


{-| TODO
-}
function : String -> Decoder a -> Value -> Request a
function =
    Private.CloudCode.function


{-| TODO
-}
job : String -> Value -> Request {}
job =
    Private.CloudCode.job
