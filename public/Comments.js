import {Elm} from '../src/Main.elm'

window.startComments = ({node, endpoint, accessKey, discussionId}) =>
    Elm.Main.init({node, flags: {endpoint, accessKey, discussionId}});


