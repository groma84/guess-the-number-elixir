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
    = Playing
    | NotConnected
    | Won


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
    | ResultReceived (Result Http.Error String)


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
                url =
                    Url.Builder.relative [ "api", "session", "connect" ] []

                cmd =
                    Http.get { url = url, expect = Http.expectJson Connected sessionIdDecoder }
            in
            ( model, cmd )

        Connected result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok sessionId ->
                    ( { model | sessionId = Just sessionId, state = Playing }, Cmd.none )

        Disconnect ->
            case model.sessionId of
                Just sId ->
                    let
                        url =
                            Url.Builder.relative [ "api", "session", "disconnect" ] [ Url.Builder.int "sessionId" sId ]

                        cmd =
                            Http.get { url = url, expect = Http.expectWhatever Disconnected }
                    in
                    ( model, cmd )

                Nothing ->
                    ( model, Cmd.none )

        Disconnected result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok _ ->
                    init ()

        GuessChanged newGuess ->
            ( { model | guess = newGuess }, Cmd.none )

        SendGuess ->
            case ( model.sessionId, String.isEmpty model.guess ) of
                ( Just sId, false ) ->
                    let
                        url =
                            Url.Builder.relative [ "api", "guess" ] [ Url.Builder.string "guess" model.guess, Url.Builder.int "sessionId" sId ]

                        cmd =
                            Http.get { url = url, expect = Http.expectJson ResultReceived resultDecoder }
                    in
                    ( { model | result = Nothing }, cmd )

                ( _, _ ) ->
                    ( model, Cmd.none )

        ResultReceived result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok r ->
                    case r of
                        "correct" ->
                            ( { model | result = Just r, state = Won }, Cmd.none )

                        _ ->
                            ( { model | result = Just r }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        resultText =
            case model.result of
                Nothing ->
                    ""

                Just r ->
                    case r of
                        "correct" ->
                            "Correct!"

                        "already_guessed" ->
                            "Already guessed that."

                        "wrong_higher" ->
                            "You need to guess higher!"

                        "wrong_lower" ->
                            "You need to guess lower!"

                        _ ->
                            ""

        disconnectButton =
            button [ type_ "button", onClick Disconnect ] [ text "Disconnect" ]

        wonView =
            div [] [ text "You have WON!", disconnectButton ]

        playView =
            div []
                [ input [ type_ "number", Html.Attributes.min "1", Html.Attributes.max "100", placeholder "Input number from 1 to 100", onInput GuessChanged, required True ] []
                , button [ type_ "button", onClick SendGuess ] [ text "Send guess" ]
                , div [] [ text resultText ]
                , disconnectButton
                ]

        notConnectedView =
            div []
                [ button [ type_ "button", onClick Connect ] [ text "Connect" ]
                ]

        shownView =
            case model.state of
                Playing ->
                    playView

                NotConnected ->
                    notConnectedView

                Won ->
                    wonView
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
