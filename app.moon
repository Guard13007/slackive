lapis = require "lapis"

import respond_to, json_params from require "lapis.application"
import slack_token, error_channel, bot_name from require "secret"

Messages = require "models.Messages"

class extends lapis.Application
    [update: "/update"]: respond_to {
        GET: =>
            @html ->
                p ->
                    text "Please look at the "
                    a href: "https://github.com/Guard13007/slackive", "readme"
                    text " to see how to use this properly. :P"

        POST: json_params =>
            if @params.token == slack_token --TODO REPLACE WITH CONST TIME COMPARE!
                message = Messages\create {
                    team_id: @params.team_id
                    team_domain: @params.team_domain
                    channel_id: @params.channel_id
                    channel_name: @params.channel_name
                    timestamp: @params.timestamp
                    user_id: @params.user_id
                    user_name: @params.user_name
                    text: @params.text
                }
                unless message
                    return {
                        json: {
                            channel: error_channel
                            username: bot_name
                            text: "Error occured saving message from #{@paramd.user_name}:\n#{@params.text}\nSent at #{@params.timestamp} in #{@params.channel_name}."
                            icon_emoji: ":warning:"
                        }}
            else
                return status: 404 -- I dunno who you think you are
    }
