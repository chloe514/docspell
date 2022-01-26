module Comp.BoxSummaryView exposing (..)

import Api
import Api.Model.ItemQuery exposing (ItemQuery)
import Api.Model.SearchStats exposing (SearchStats)
import Comp.Basic
import Comp.SearchStatsView
import Data.BoxContent exposing (SearchQuery(..), SummaryData, SummaryShow(..))
import Data.Flags exposing (Flags)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Http
import Messages.Comp.BoxSummaryView exposing (Texts)
import Styles
import Util.List


type alias Model =
    { results : ViewResult
    , show : SummaryShow
    }


type ViewResult
    = Loading
    | Loaded SearchStats
    | Failed Http.Error


type Msg
    = StatsResp (Result Http.Error SearchStats)


init : Flags -> SummaryData -> ( Model, Cmd Msg )
init flags data =
    ( { results = Loading
      , show = data.show
      }
    , case data.query of
        SearchQueryString q ->
            Api.itemSearchStats flags (mkQuery q) StatsResp

        SearchQueryBookmark bmId ->
            Api.itemSearchStatsBookmark flags (mkQuery bmId) StatsResp
    )



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StatsResp (Ok stats) ->
            ( { model | results = Loaded stats }, Cmd.none )

        StatsResp (Err err) ->
            ( { model | results = Failed err }, Cmd.none )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    case model.results of
        Loading ->
            div [ class "h-24 " ]
                [ Comp.Basic.loadingDimmer
                    { label = ""
                    , active = True
                    }
                ]

        Failed err ->
            div
                [ class "py-4"
                , class Styles.errorMessage
                ]
                [ text texts.errorOccurred
                , text ": "
                , text (texts.httpError err)
                ]

        Loaded stats ->
            case model.show of
                Data.BoxContent.SummaryShowFields flag ->
                    Comp.SearchStatsView.view2
                        texts.statsView
                        flag
                        ""
                        stats

                SummaryShowGeneral ->
                    viewGeneral texts stats


viewGeneral : Texts -> SearchStats -> Html Msg
viewGeneral texts stats =
    let
        tagCount =
            List.length stats.tagCloud.items

        fieldCount =
            List.length stats.fieldStats

        orgCount =
            List.length stats.corrOrgStats

        persCount =
            (stats.corrPersStats ++ stats.concPersStats)
                |> List.map (.ref >> .id)
                |> Util.List.distinct
                |> List.length

        equipCount =
            List.length stats.concEquipStats

        mklabel name =
            div [ class "py-1 text-lg" ] [ text name ]

        value num =
            div [ class "py-1 font-mono text-lg" ] [ text <| String.fromInt num ]
    in
    div [ class "opacity-90" ]
        [ div [ class "flex flex-row" ]
            [ div [ class "flex flex-col mr-4" ]
                [ mklabel texts.basics.items
                , mklabel texts.basics.tags
                , mklabel texts.basics.customFields
                , mklabel texts.basics.organization
                , mklabel texts.basics.person
                , mklabel texts.basics.equipment
                ]
            , div [ class "flex flex-col" ]
                [ value stats.count
                , value tagCount
                , value fieldCount
                , value orgCount
                , value persCount
                , value equipCount
                ]
            ]
        ]



--- Helpers


mkQuery : String -> ItemQuery
mkQuery query =
    { query = query
    , limit = Nothing
    , offset = Nothing
    , searchMode = Nothing
    , withDetails = Nothing
    }
