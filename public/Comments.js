import {Elm} from '../src/Main.elm'

window.startComments = ({node, endpoint, accessKey, discussionId, elmUIEmbedded = false}) =>
    Elm.Main.init({node, flags: {dataConfig: {endpoint, accessKey, discussionId}, elmUIEmbedded}});


