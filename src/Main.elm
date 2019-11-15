module Main exposing (..)

import Browser
import Element exposing (Element)
import Html exposing (..)
import Json.Decode



-- MODEL --


type Model
    = Loading


init : Json.Decode.Value -> ( Model, Cmd Msg )
init flags =
    ( Loading
    , Cmd.none
    )


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- UPDATE --


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW --


view : Model -> Html Msg
view model =
    Element.layout [] <|
        Element.text "PPP"
