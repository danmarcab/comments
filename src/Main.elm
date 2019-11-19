module Main exposing (..)

import Api.InputObject as InputObject
import Api.Mutation as Mutation
import Api.Object
import Api.Object.Comment
import Api.Object.CommentPage
import Api.Query as Query
import Api.Scalar exposing (Id(..))
import AssocList
import Browser
import Browser.Dom
import Comments exposing (Comment, Comments, RawComment, RawComments)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument as OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (..)
import Html.Attributes
import Task



-- MODEL --


type alias Model =
    { dataConfig : DataConfig
    , styleConfig : StyleConfig
    , newComment : NewComment
    , comments : CommentData
    }


type NewComment
    = Writing String
    | Sending String


type alias DataConfig =
    { discussionId : String
    , endpoint : String
    , accessKey : String
    }


type alias Color =
    Element.Color


type alias StyleConfig =
    { backgroundColor : Color
    , commentBackgroundColor : Color
    , commentPadding : Int
    , titleFontColor : Color
    , titleFontSize : Int
    , textFontColor : Color
    , textFontSize : Int
    , roundCorners : Int
    , buttonBackgroundColor : Color
    , buttonTextColor : Color
    , buttonPadding : Int
    , buttonBorderColor : Color
    , spacing : Int
    }


defaultStyleConfig : StyleConfig
defaultStyleConfig =
    { backgroundColor = Element.rgba 1 1 1 0
    , commentBackgroundColor = Element.rgb255 245 243 242
    , commentPadding = 10
    , titleFontColor = Element.rgb 0.2 0.2 0.2
    , titleFontSize = 24
    , textFontColor = Element.rgb 0.2 0.2 0.2
    , textFontSize = 20
    , roundCorners = 0
    , buttonBackgroundColor = Element.rgb255 210 210 210
    , buttonTextColor = Element.rgb 0.2 0.2 0.2
    , buttonBorderColor = Element.rgb 0.2 0.2 0.2
    , buttonPadding = 5
    , spacing = 10
    }


type CommentData
    = Loading
    | Error
    | Loaded
        { comments : Comments
        , collapsedReplies : AssocList.Dict Id ()
        , newReplies : AssocList.Dict Id NewComment
        }


init :
    DataConfig
    -> ( Model, Cmd Msg )
init flags =
    let
        model =
            { dataConfig = flags
            , styleConfig = defaultStyleConfig
            , newComment = Writing ""
            , comments = Loading
            }
    in
    ( model
    , commentsRequest flags
    )


commentsQuery : String -> SelectionSet RawComments RootQuery
commentsQuery discussionId =
    Query.commentsByDiscussionId identity
        { discussionId = discussionId }
        (Api.Object.CommentPage.data commentSet
            |> SelectionSet.map (List.filterMap identity)
        )


commentSet : SelectionSet RawComment Api.Object.Comment
commentSet =
    SelectionSet.map3 RawComment
        Api.Object.Comment.id_
        Api.Object.Comment.content
        (Api.Object.Comment.parent Api.Object.Comment.id_)


commentsRequest : DataConfig -> Cmd Msg
commentsRequest dataConfig =
    commentsQuery dataConfig.discussionId
        |> Graphql.Http.queryRequest dataConfig.endpoint
        |> Graphql.Http.withHeader "authorization" ("Bearer " ++ dataConfig.accessKey)
        |> Graphql.Http.send GotComments


submitCommentRequest :
    DataConfig
    -> (Result (Graphql.Http.Error { id : Id, content : String }) { id : Id, content : String } -> Msg)
    -> { content : String, parent : Maybe Id }
    -> Cmd Msg
submitCommentRequest dataConfig msg { content, parent } =
    newCommentMutation dataConfig.discussionId content parent
        |> Graphql.Http.mutationRequest dataConfig.endpoint
        |> Graphql.Http.withHeader "authorization" ("Bearer " ++ dataConfig.accessKey)
        |> Graphql.Http.send msg


newCommentMutation : String -> String -> Maybe Id -> SelectionSet { id : Id, content : String } RootMutation
newCommentMutation discussionId content mParent =
    Mutation.createComment
        { data =
            InputObject.buildCommentInput
                { discussionId = discussionId
                , content = content
                }
                (\args ->
                    { args
                        | parent =
                            OptionalArgument.fromMaybe mParent
                                |> OptionalArgument.map
                                    (\parent ->
                                        InputObject.buildCommentParentRelation
                                            (\opts -> { opts | connect = Present parent })
                                    )
                    }
                )
        }
        (SelectionSet.map2 (\id returnedContent -> { id = id, content = returnedContent })
            Api.Object.Comment.id_
            Api.Object.Comment.content
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
    | GotComments (Result (Graphql.Http.Error Comments.RawComments) Comments.RawComments)
    | RetryFetchCommentsClicked
    | UpdateNewCommentContent String
    | SubmitNewComment
    | GotNewComment (Result (Graphql.Http.Error { id : Id, content : String }) { id : Id, content : String })
    | ToggleCollapse Id
    | StartReply Id
    | UpdateReply Id String
    | SubmitReply Id
    | GotNewReply Id (Result (Graphql.Http.Error { id : Id, content : String }) { id : Id, content : String })


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.comments of
        Loading ->
            case msg of
                GotComments (Err _) ->
                    ( { model | comments = Error }, Cmd.none )

                GotComments (Ok rawComments) ->
                    ( { model
                        | comments =
                            Loaded <|
                                { comments = Comments.fromRaw rawComments
                                , collapsedReplies = AssocList.empty
                                , newReplies = AssocList.empty
                                }
                      }
                    , Cmd.none
                    )

                NoOp ->
                    ( model, Cmd.none )

                _ ->
                    ( model, logInvalidMsg model msg )

        Error ->
            case msg of
                RetryFetchCommentsClicked ->
                    ( { model | comments = Loading }, commentsRequest model.dataConfig )

                NoOp ->
                    ( model, Cmd.none )

                _ ->
                    ( model, logInvalidMsg model msg )

        Loaded commentData ->
            case msg of
                UpdateNewCommentContent str ->
                    ( { model | newComment = Writing str }, Cmd.none )

                SubmitNewComment ->
                    case model.newComment of
                        Writing content ->
                            ( { model | newComment = Sending content }
                            , submitCommentRequest
                                model.dataConfig
                                GotNewComment
                                { content = content
                                , parent = Nothing
                                }
                            )

                        Sending _ ->
                            ( model, Cmd.none )

                GotNewComment (Err _) ->
                    ( model, Cmd.none )

                GotNewComment (Ok { id, content }) ->
                    ( let
                        newCommentData =
                            { commentData
                                | comments =
                                    Comments.append
                                        { id = id
                                        , content = content
                                        , replies = Comments.empty
                                        }
                                        commentData.comments
                            }
                      in
                      { model
                        | comments = Loaded newCommentData
                        , newComment = Writing ""
                      }
                    , scrollTo (idToString id)
                    )

                ToggleCollapse id ->
                    ( let
                        newCommentData =
                            { commentData
                                | collapsedReplies =
                                    AssocList.update id
                                        (\m ->
                                            case m of
                                                Just () ->
                                                    Nothing

                                                Nothing ->
                                                    Just ()
                                        )
                                        commentData.collapsedReplies
                            }
                      in
                      { model | comments = Loaded newCommentData }
                    , Cmd.none
                    )

                StartReply id ->
                    ( let
                        newCommentData =
                            { commentData
                                | newReplies =
                                    AssocList.update id
                                        (\r ->
                                            case r of
                                                Just _ ->
                                                    r

                                                Nothing ->
                                                    Just (Writing "")
                                        )
                                        commentData.newReplies
                            }
                      in
                      { model | comments = Loaded newCommentData }
                    , focusTo <| "newReply" ++ idToString id
                    )

                UpdateReply id content ->
                    ( let
                        newCommentData =
                            { commentData
                                | newReplies =
                                    AssocList.update id
                                        (\r ->
                                            case r of
                                                Just (Writing _) ->
                                                    Just (Writing content)

                                                Just (Sending _) ->
                                                    r

                                                Nothing ->
                                                    Nothing
                                        )
                                        commentData.newReplies
                            }
                      in
                      { model | comments = Loaded newCommentData }
                    , Cmd.none
                    )

                SubmitReply id ->
                    case AssocList.get id commentData.newReplies of
                        Just (Writing content) ->
                            let
                                newCommentData =
                                    { commentData
                                        | newReplies =
                                            AssocList.insert id
                                                (Sending content)
                                                commentData.newReplies
                                    }
                            in
                            ( { model | comments = Loaded newCommentData }
                            , submitCommentRequest
                                model.dataConfig
                                (GotNewReply id)
                                { content = content
                                , parent = Just id
                                }
                            )

                        Just (Sending _) ->
                            ( model, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                GotNewReply parentId (Err _) ->
                    ( model, Cmd.none )

                GotNewReply parentId (Ok { id, content }) ->
                    ( let
                        newCommentData =
                            { commentData
                                | comments =
                                    Comments.appendReply parentId
                                        { id = id
                                        , content = content
                                        , replies = Comments.empty
                                        }
                                        commentData.comments
                                , newReplies =
                                    AssocList.remove parentId commentData.newReplies
                            }
                      in
                      { model
                        | comments = Loaded newCommentData
                      }
                    , scrollTo (idToString id)
                    )

                NoOp ->
                    ( model, Cmd.none )

                _ ->
                    ( model, logInvalidMsg model msg )


scrollTo : String -> Cmd Msg
scrollTo htmlId =
    Browser.Dom.getElement htmlId
        |> Task.andThen
            (\{ viewport, element } ->
                let
                    finalY =
                        element.y - ((viewport.height - element.height) / 2)
                in
                Browser.Dom.setViewport 0 finalY
            )
        |> Task.attempt (\_ -> NoOp)


focusTo : String -> Cmd Msg
focusTo htmlId =
    Browser.Dom.focus htmlId
        |> Task.attempt (\_ -> NoOp)


{-| TODO: properly log this
-}
logInvalidMsg : Model -> Msg -> Cmd Msg
logInvalidMsg model msg =
    Cmd.none


idToString : Id -> String
idToString (Id id) =
    id



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW --


view : Model -> Html Msg
view model =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.width Element.fill
        , Background.color model.styleConfig.backgroundColor
        ]
    <|
        case model.comments of
            Loading ->
                Element.text "loading..."

            Error ->
                Element.text "Error"

            Loaded { comments, collapsedReplies, newReplies } ->
                Element.column
                    [ Element.width Element.fill
                    , Element.spacing model.styleConfig.spacing
                    ]
                    [ Element.paragraph
                        [ Font.size model.styleConfig.titleFontSize
                        , Font.color model.styleConfig.titleFontColor
                        ]
                        [ Element.text "Add your comment"
                        ]
                    , addCommentView model.styleConfig Nothing UpdateNewCommentContent SubmitNewComment model.newComment
                    , Element.paragraph
                        [ Font.size model.styleConfig.titleFontSize
                        , Font.color model.styleConfig.titleFontColor
                        ]
                        [ Element.text <| String.fromInt (Comments.countAll comments) ++ " comments"
                        ]
                    , commentsView model.styleConfig collapsedReplies newReplies comments
                    , Element.paragraph
                        [ Font.size model.styleConfig.titleFontSize
                        , Font.color model.styleConfig.titleFontColor
                        ]
                        [ Element.text "Add your comment"
                        ]
                    , addCommentView model.styleConfig Nothing UpdateNewCommentContent SubmitNewComment model.newComment
                    ]


addCommentView : StyleConfig -> Maybe String -> (String -> Msg) -> Msg -> NewComment -> Element Msg
addCommentView style maybeHtmlId onChange submit newComment =
    case newComment of
        Writing content ->
            Element.column
                [ Element.width Element.fill
                , Background.color style.commentBackgroundColor
                , Element.padding style.spacing
                , Border.rounded style.roundCorners
                , Element.spacing style.spacing
                ]
                [ Input.multiline
                    [ Element.width Element.fill
                    , Element.height (Element.shrink |> Element.minimum (style.textFontSize * 10))
                    , Element.htmlAttribute (Html.Attributes.id (maybeHtmlId |> Maybe.withDefault ""))
                    ]
                    { label = Input.labelHidden "Enter your comment"
                    , onChange = onChange
                    , placeholder = Nothing
                    , spellcheck = False
                    , text = content
                    }
                , submitNewCommentButton style submit
                ]

        Sending _ ->
            Element.el
                [ Element.width Element.fill
                , Background.color style.commentBackgroundColor
                , Element.padding style.spacing
                , Border.rounded style.roundCorners
                , Element.spacing style.spacing
                ]
            <|
                Element.text "Your comment is being sent..."


submitNewCommentButton : StyleConfig -> Msg -> Element Msg
submitNewCommentButton style submit =
    Element.el [ Element.alignRight ] <|
        Input.button
            [ Element.padding style.buttonPadding
            , Background.color style.buttonBackgroundColor
            , Border.rounded style.roundCorners
            , Border.color style.buttonBorderColor
            , Border.width 1
            , Element.mouseOver [ Element.moveDown 1 ]
            ]
            { onPress = Just submit
            , label = Element.text "Add your comment"
            }


commentsView :
    StyleConfig
    -> AssocList.Dict Id ()
    -> AssocList.Dict Id NewComment
    -> Comments
    -> Element Msg
commentsView style collapsedReplies newReplies comments =
    if comments == Comments.empty then
        Element.none

    else
        Element.column
            [ Element.width Element.fill
            , Element.spacing style.spacing
            ]
            (List.map (commentView style collapsedReplies newReplies) (Comments.toList comments))


commentView :
    StyleConfig
    -> AssocList.Dict Id ()
    -> AssocList.Dict Id NewComment
    -> Comment
    -> Element Msg
commentView style collapsedReplies newReplies { content, replies, id } =
    let
        collapsed =
            AssocList.member id collapsedReplies

        newReply =
            AssocList.get id newReplies

        showReplies =
            replies /= Comments.empty || newReply /= Nothing
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing style.spacing
        , Element.htmlAttribute (Html.Attributes.id (idToString id))
        ]
        [ Element.column
            [ Element.width Element.fill
            , Element.spacing style.spacing
            , Background.color style.commentBackgroundColor
            , Element.padding style.commentPadding
            , Border.rounded style.roundCorners
            ]
            [ Element.paragraph
                [ Element.width Element.fill
                ]
                [ Element.text content ]
            , Input.button
                [ Element.alignRight
                , Font.underline
                ]
                { onPress = Just <| StartReply id
                , label = Element.text "Reply"
                }
            ]
        , if showReplies then
            Element.row
                [ Element.width Element.fill
                ]
                [ Input.button
                    [ Element.width (Element.px (style.textFontSize * 2))
                    , Element.alignTop
                    , Font.center
                    ]
                    { onPress = Just (ToggleCollapse id)
                    , label =
                        Element.text
                            (if collapsed then
                                "▶"

                             else
                                "▼"
                            )
                    }
                , Element.column
                    [ Element.width Element.fill
                    , Element.spacing style.spacing
                    ]
                    [ if collapsed then
                        Input.button [ Element.width Element.fill ]
                            { onPress = Just (ToggleCollapse id)
                            , label =
                                Element.paragraph [ Element.width Element.fill ]
                                    [ Element.text <|
                                        "This comment has "
                                            ++ String.fromInt (Comments.count replies)
                                            ++ " direct replies and "
                                            ++ String.fromInt (Comments.countAll replies)
                                            ++ " total replies"
                                    ]
                            }

                      else
                        commentsView style collapsedReplies newReplies replies
                    , case newReply of
                        Just reply ->
                            Element.el
                                [ Element.width Element.fill
                                ]
                            <|
                                addCommentView style (Just <| "newReply" ++ idToString id) (UpdateReply id) (SubmitReply id) reply

                        Nothing ->
                            Element.none
                    ]
                ]

          else
            Element.none
        ]
