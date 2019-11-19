module Comments exposing
    ( Comment
    , Comments
    , RawComment
    , RawComments
    , append
    , appendReply
    , count
    , countAll
    , empty
    , fromList
    , fromRaw
    , toList
    )

import Api.Scalar exposing (Id(..))
import AssocList


type alias RawComment =
    { id : Id
    , content : String
    , parent : Maybe Id
    }


type alias RawComments =
    List RawComment


{-| As comments are usually only appended, we'll store them reversed
-}
type Comments
    = Comments (List Comment)


type alias Comment =
    { id : Id
    , content : String
    , replies : Comments
    }


fromRaw :
    RawComments
    -> Comments
fromRaw rawComments =
    let
        ( repliesByParent, reversefirstLevelComments ) =
            List.foldl
                (\comment ( replies, firstLevelComments ) ->
                    case comment.parent of
                        Just parentId ->
                            ( AssocList.update parentId
                                (\mReplyList ->
                                    case mReplyList of
                                        Just replyList ->
                                            Just (comment :: replyList)

                                        Nothing ->
                                            Just [ comment ]
                                )
                                replies
                            , firstLevelComments
                            )

                        Nothing ->
                            ( replies, comment :: firstLevelComments )
                )
                ( AssocList.empty, [] )
                rawComments

        mapRawComment raw =
            { id = raw.id
            , content = raw.content
            , replies =
                AssocList.get
                    raw.id
                    repliesByParent
                    |> Maybe.map (List.map mapRawComment)
                    |> Maybe.withDefault []
                    |> List.reverse
                    |> fromList
            }
    in
    fromList <|
        List.map
            mapRawComment
            (List.reverse reversefirstLevelComments)


empty : Comments
empty =
    fromList []


fromList : List Comment -> Comments
fromList commentList =
    Comments (List.reverse commentList)


toList : Comments -> List Comment
toList (Comments commentList) =
    List.reverse commentList


append : Comment -> Comments -> Comments
append comment (Comments comments) =
    Comments <| comment :: comments


appendReply : Id -> Comment -> Comments -> Comments
appendReply parent comment (Comments comments) =
    Comments <|
        List.map
            (\c ->
                if c.id == parent then
                    { c | replies = append comment c.replies }

                else
                    { c | replies = appendReply parent comment c.replies }
            )
            comments


count : Comments -> Int
count (Comments comments) =
    List.length comments


countAll : Comments -> Int
countAll (Comments comments) =
    List.map
        (\comment ->
            1 + countAll comment.replies
        )
        comments
        |> List.sum
