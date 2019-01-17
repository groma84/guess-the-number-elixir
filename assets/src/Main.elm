module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode
import Json.Encode
import Url.Builder


type State
    = NotConnected
    | Playing


type alias Model =
    { state : State
    , sessionId : Maybe Int
    , guess : String
    , result : Maybe String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { state = NotConnected, sessionId = Nothing, guess = "", result = Nothing }, Cmd.none )


type Msg
    = Connect
    | Connected (Result Http.Error Int)
    | Disconnect
    | Disconnected (Result Http.Error ())
    | GuessChanged String
    | SendGuess
    | GuessResultReceived (Result Http.Error String)


sessionIdDecoder : Json.Decode.Decoder Int
sessionIdDecoder =
    Json.Decode.field "sessionId" Json.Decode.int


resultDecoder : Json.Decode.Decoder String
resultDecoder =
    Json.Decode.field "result" Json.Decode.string


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Connect ->
            let
                requestUrl =
                    Url.Builder.relative [ "api", "session", "connect" ] []

                getCmd =
                    Http.get { url = requestUrl, expect = Http.expectJson Connected sessionIdDecoder }
            in
            ( model, getCmd )

        Connected result ->
            let
                newModel =
                    case result of
                        Ok sessionId ->
                            { model | sessionId = Just sessionId, state = Playing }

                        Err err ->
                            { model | sessionId = Nothing, state = NotConnected }
            in
            ( newModel, Cmd.none )

        Disconnect ->
            let
                disconnectCmd =
                    case model.sessionId of
                        Nothing ->
                            Cmd.none

                        Just sId ->
                            let
                                requestUrl =
                                    Url.Builder.relative [ "api", "session", "disconnect" ] [ Url.Builder.int "sessionId" sId ]
                            in
                            Http.get { url = requestUrl, expect = Http.expectWhatever Disconnected }
            in
            ( model, disconnectCmd )

        Disconnected result ->
            init ()

        GuessChanged guess ->
            ( { model | guess = guess }, Cmd.none )

        SendGuess ->
            if String.isEmpty model.guess then
                ( model, Cmd.none )

            else
                case model.sessionId of
                    Nothing ->
                        ( model, Cmd.none )

                    Just sId ->
                        let
                            requestUrl =
                                Url.Builder.relative [ "api", "guess" ] [ Url.Builder.string "guess" model.guess, Url.Builder.int "sessionId" sId ]

                            getCmd =
                                Http.get { url = requestUrl, expect = Http.expectJson GuessResultReceived resultDecoder }
                        in
                        ( model, getCmd )

        GuessResultReceived result ->
            let
                extractedResult =
                    case result of
                        Ok r ->
                            r

                        Err _ ->
                            "fatal_error"
            in
            ( { model | result = Just extractedResult }, Cmd.none )


humanReadableResult : String -> String
humanReadableResult result =
    case result of
        "fatal_error" ->
            "A fatal error occured. Sorry!"

        "correct" ->
            "You have won!"

        "wrong_higher" ->
            "You guessed too low. Try a higher number."

        "wrong_lower" ->
            "You guessed too high - try a lower number."

        "already_guessed" ->
            "You already tried that number."

        _ ->
            "Invalid response received."


view : Model -> Html Msg
view model =
    let
        playView =
            div [ style "display" "flex", style "flex-direction" "column" ]
                [ input [ type_ "number", onInput GuessChanged, Html.Attributes.min "1", Html.Attributes.max "100", required True, placeholder "Guess a number between 1 and 100" ] []
                , case model.result of
                    Nothing ->
                        button [ onClick SendGuess ] [ text "Send guess" ]

                    Just r ->
                        if r == "correct" then
                            text ""

                        else
                            button [ onClick SendGuess ] [ text "Send guess" ]
                , button [ onClick Disconnect ] [ text "Disconnect" ]
                , case model.result of
                    Nothing ->
                        text ""

                    Just r ->
                        p [] [ text (humanReadableResult r) ]
                ]

        notConnectedView =
            div [] [ button [ onClick Connect ] [ text "Connect" ] ]

        shownView =
            case model.state of
                NotConnected ->
                    notConnectedView

                Playing ->
                    playView
    in
    div [] [ shownView ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
