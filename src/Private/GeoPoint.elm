module Private.GeoPoint exposing
    ( GeoPoint
    , decode
    , encode
    , geoPoint
    , latitude
    , longitude
    )

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Parse.Decode as Decode
import Private.Decode as Decode


type GeoPoint
    = GeoPoint
        { latitude : Float
        , longitude : Float
        }


geoPoint : { latitude : Float, longitude : Float } -> GeoPoint
geoPoint =
    GeoPoint


latitude : GeoPoint -> Float
latitude (GeoPoint geoPoint_) =
    geoPoint_.latitude


longitude : GeoPoint -> Float
longitude (GeoPoint geoPoint_) =
    geoPoint_.longitude


decode : Decoder GeoPoint
decode =
    Decode.parseTypeDecoder "GeoPoint"
        (Decode.succeed
            (\latitude_ longitude_ ->
                geoPoint { latitude = latitude_, longitude = longitude_ }
            )
            |> Decode.required "latitude" Decode.float
            |> Decode.required "longitude" Decode.float
        )


encode : GeoPoint -> Value
encode geoPoint_ =
    Encode.object
        [ ( "__type", Encode.string "GeoPoint" )
        , ( "latitude", Encode.float (latitude geoPoint_) )
        , ( "longitude", Encode.float (longitude geoPoint_) )
        ]
