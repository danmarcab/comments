-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Api.InputObject exposing (..)

import Api.Interface
import Api.Object
import Api.Scalar
import Api.ScalarCodecs
import Api.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


buildCommentInput : CommentInputRequiredFields -> (CommentInputOptionalFields -> CommentInputOptionalFields) -> CommentInput
buildCommentInput required fillOptionals =
    let
        optionals =
            fillOptionals
                { parent = Absent }
    in
    CommentInput { discussionId = required.discussionId, content = required.content, parent = optionals.parent }


type alias CommentInputRequiredFields =
    { discussionId : String
    , content : String
    }


type alias CommentInputOptionalFields =
    { parent : OptionalArgument CommentParentRelation }


{-| Type alias for the `CommentInput` attributes. Note that this type
needs to use the `CommentInput` type (not just a plain type alias) because it has
references to itself either directly (recursive) or indirectly (circular). See
<https://github.com/dillonkearns/elm-graphql/issues/33>.
-}
type alias CommentInputRaw =
    { discussionId : String
    , content : String
    , parent : OptionalArgument CommentParentRelation
    }


{-| Type for the CommentInput input object.
-}
type CommentInput
    = CommentInput CommentInputRaw


{-| Encode a CommentInput into a value that can be used as an argument.
-}
encodeCommentInput : CommentInput -> Value
encodeCommentInput (CommentInput input) =
    Encode.maybeObject
        [ ( "discussionId", Encode.string input.discussionId |> Just ), ( "content", Encode.string input.content |> Just ), ( "parent", encodeCommentParentRelation |> Encode.optional input.parent ) ]


buildCommentParentRelation : (CommentParentRelationOptionalFields -> CommentParentRelationOptionalFields) -> CommentParentRelation
buildCommentParentRelation fillOptionals =
    let
        optionals =
            fillOptionals
                { create = Absent, connect = Absent, disconnect = Absent }
    in
    CommentParentRelation { create = optionals.create, connect = optionals.connect, disconnect = optionals.disconnect }


type alias CommentParentRelationOptionalFields =
    { create : OptionalArgument CommentInput
    , connect : OptionalArgument Api.ScalarCodecs.Id
    , disconnect : OptionalArgument Bool
    }


{-| Type alias for the `CommentParentRelation` attributes. Note that this type
needs to use the `CommentParentRelation` type (not just a plain type alias) because it has
references to itself either directly (recursive) or indirectly (circular). See
<https://github.com/dillonkearns/elm-graphql/issues/33>.
-}
type alias CommentParentRelationRaw =
    { create : OptionalArgument CommentInput
    , connect : OptionalArgument Api.ScalarCodecs.Id
    , disconnect : OptionalArgument Bool
    }


{-| Type for the CommentParentRelation input object.
-}
type CommentParentRelation
    = CommentParentRelation CommentParentRelationRaw


{-| Encode a CommentParentRelation into a value that can be used as an argument.
-}
encodeCommentParentRelation : CommentParentRelation -> Value
encodeCommentParentRelation (CommentParentRelation input) =
    Encode.maybeObject
        [ ( "create", encodeCommentInput |> Encode.optional input.create ), ( "connect", (Api.ScalarCodecs.codecs |> Api.Scalar.unwrapEncoder .codecId) |> Encode.optional input.connect ), ( "disconnect", Encode.bool |> Encode.optional input.disconnect ) ]