module Parse.Private.File exposing (ContentType, File(..), deleteFile, encodeFile, fileDecoder, name, uploadFile, url)

import Bytes exposing (Bytes)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Parse.Private.Request as Request exposing (Request, binaryRequestWithAdditionalHeaders, request)
import Url


type File
    = File
        { name : String
        , url : String
        }


name : File -> String
name (File file_) =
    file_.name


url : File -> String
url (File file_) =
    file_.url


encodeFile : File -> Value
encodeFile file =
    Encode.object
        [ ( "name", Encode.string (name file) )
        , ( "url", Encode.string (url file) )
        ]


fileDecoder : Decoder File
fileDecoder =
    Decode.succeed (\name_ url_ -> File { name = name_, url = url_ })
        |> Decode.required "name" Decode.string
        |> Decode.required "url" Decode.string


type alias ContentType =
    String


uploadFile : String -> ContentType -> Bytes -> Request File
uploadFile fileName contentType file =
    binaryRequestWithAdditionalHeaders
        { method = "POST"
        , additionalHeaders = [ Http.header "Content-Type" contentType ]
        , endpoint = "/files/" ++ Url.percentEncode fileName
        , contentType = contentType
        , body = file
        , decoder = fileDecoder
        }


deleteFile : File -> Request {}
deleteFile file =
    request
        { method = "DELETE"
        , endpoint = "/files/" ++ name file
        , body = Nothing
        , decoder = Decode.succeed {}
        }
