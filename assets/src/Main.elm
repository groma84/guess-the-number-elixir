module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode
import Json.Encode
import Url.Builder



-- ---------------------------
-- MODEL
-- ---------------------------


type alias SessionId =
    Int


type State
    = NotConnected
    | Playing


type GuessResult
    = FatalError
    | Correct
    | WrongHigher
    | WrongLower
    | AlreadyGuessed


type alias Model =
    { state : State
    , sessionId : Maybe SessionId
    , guessString : String
    , guess : Maybe Int
    , lastGuessResult : Maybe GuessResult
    }


init : () -> ( Model, Cmd Msg )
init flags =
    ( { state = NotConnected
      , sessionId = Nothing
      , guessString = ""
      , guess = Nothing
      , lastGuessResult = Nothing
      }
    , Cmd.none
    )



-- JSON


connectDecoder =
    Json.Decode.field "sessionId" Json.Decode.int


resultDecoder =
    Json.Decode.field "result" Json.Decode.string



-- ---------------------------
-- UPDATE
-- ---------------------------


type Msg
    = Connect
    | Connected (Result Http.Error SessionId)
    | Disconnect
    | Disconnected (Result Http.Error ())
    | GuessChanged String
    | SendGuess
    | GuessResultReceived (Result Http.Error String)


parseResultString : String -> GuessResult
parseResultString s =
    case s of
        "fatal_error" ->
            FatalError

        "correct" ->
            Correct

        "wrong_higher" ->
            WrongHigher

        "wrong_lower" ->
            WrongLower

        "already_guessed" ->
            AlreadyGuessed

        _ ->
            FatalError


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Connect ->
            let
                requestUrl =
                    Url.Builder.relative [ "api", "session", "connect" ] []

                getCmd =
                    Http.get { url = requestUrl, expect = Http.expectJson Connected connectDecoder }
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

        Disconnected _ ->
            init ()

        GuessChanged guessString ->
            ( { model | guessString = guessString, guess = String.toInt guessString }, Cmd.none )

        SendGuess ->
            let
                guessCmd =
                    case ( model.sessionId, model.guess ) of
                        ( Just sId, Just g ) ->
                            let
                                requestUrl =
                                    Url.Builder.relative [ "api", "guess" ] [ Url.Builder.int "sessionId" sId, Url.Builder.int "guess" g ]
                            in
                            Http.get { url = requestUrl, expect = Http.expectJson GuessResultReceived resultDecoder }

                        ( _, _ ) ->
                            Cmd.none
            in
            ( { model | lastGuessResult = Nothing }, guessCmd )

        GuessResultReceived result ->
            case result of
                Ok s ->
                    ( { model | lastGuessResult = Just <| parseResultString s }, Cmd.none )

                Err _ ->
                    ( { model | lastGuessResult = Just FatalError }, Cmd.none )



-- ---------------------------
-- VIEW
-- ---------------------------


view : Model -> Html Msg
view model =
    let
        connectView =
            div [] [ button [ onClick Connect, autofocus True ] [ text "Start game" ] ]

        playView =
            let
                guessResultText result =
                    case result of
                        FatalError ->
                            "A fatal error occured. Sorry!"

                        Correct ->
                            "You have won!"

                        WrongHigher ->
                            "You guessed too low. Try a higher number."

                        WrongLower ->
                            "You guessed too high - try a lower number."

                        AlreadyGuessed ->
                            "You already tried that number."

                guessResult =
                    case model.lastGuessResult of
                        Nothing ->
                            p [] []

                        Just r ->
                            p [] [ text <| guessResultText r ]

                guessForm =
                    let
                        f =
                            Html.form [ onSubmit SendGuess ]
                                [ input [ type_ "number", Html.Attributes.min "1", Html.Attributes.max "100", required True, placeholder "Guess a number between 1 and 100", onInput GuessChanged ] []
                                , button [ type_ "submit" ] [ text "Send guess" ]
                                ]
                    in
                    case model.lastGuessResult of
                        Just s ->
                            case s of
                                Correct ->
                                    text ""

                                _ ->
                                    f

                        Nothing ->
                            f
            in
            div []
                [ guessForm
                , guessResult
                , button [ type_ "button", onClick Disconnect, style "margin" "5rem" ] [ text "End game" ]
                ]
    in
    div []
        [ case model.state of
            NotConnected ->
                connectView

            Playing ->
                playView
        ]



-- ---------------------------
-- MAIN
-- ---------------------------


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
