module Private.Pointer exposing
    ( Pointer(..)
    , className
    , objectId
    , pointer
    )

import Private.ObjectId exposing (..)


type Pointer a
    = Pointer String (ObjectId a)


pointer : String -> ObjectId a -> Pointer a
pointer =
    Pointer


className : Pointer a -> String
className (Pointer className_ _) =
    className_


objectId : Pointer a -> ObjectId a
objectId (Pointer _ objectId_) =
    objectId_
