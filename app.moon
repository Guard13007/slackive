lapis = require "lapis"

import respond_to, json_params from require "lapis.application"
import slack_tokens, slack_hook, error_channel, bot_name from require "secret"
import const_compare from require "helpers"

Messages = require "models.Messages"

class extends lapis.Application
    [githook: "/githook"]: respond_to {
        GET: =>
            return status: 405 --Method Not Allowed

        POST: json_params =>
            unless @params.ref ~= nil
                return { json: { status: "invalid request" } }, status: 400 --Bad Request

            if @params.ref == "refs/heads/master"
                os.execute "echo \"Updating server...\" >> logs/updates.log"
                result = 0 == os.execute "git pull origin >> logs/updates.log"
                result and= 0 == os.execute "moonc . 2>> logs/updates.log"
                result and= 0 == os.execute "lapis migrate production >> logs/updates.log"
                result and= 0 == os.execute "lapis build production >> logs/updates.log"
                if result
                    return { json: { status: "successful" } }
                else
                    return { json: { status: "failure", message: "check logs/updates.log"} }, status: 500 --Internal Server Error
            else
                return { json: { status: "successful", message: "ignored non-master push" } }
    }

    [incoming: "/incoming"]: respond_to {
        GET: =>
            @html ->
                p ->
                    text "Please look at the "
                    a href: "https://github.com/Guard13007/slackiver", "readme"
                    text " to see how to use this properly. :P"

        POST: json_params =>
            if const_compare @params.token, slack_tokens
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
                --unless message
            human_date = os.date("%c", tonumber(@params.timestamp\sub(1, @params.timestamp\find(".") - 1)))
            os.execute "curl -X POST --data-urlencode 'payload={\"channel\": \"#slackiver\", \"username\": \"The Slackiver\", \"text\": \"(On #{@params.team_domain} (#{@params.team_id}))\\nError occured saving message from #{@params.user_name} (#{@params.user_id}):\\n#{@params.text}\\n(Sent at #{human_date} in #{@params.channel_name} (#{@params.channel_id}).)\", \"icon_emoji\": \":warning:\"}' #{slack_hook}"
            --else
            --    return status: 404 -- I dunno who you think you are
    }

    [all: "/all"]: =>
        messages = Messages\select "ORDER BY timestamp ASC"
        @html ->
            if #messages > 0
                element "table", ->
                        for i in ipairs messages
                            tr ->
                                td messages[i].timestamp
                                td messages[i].team_domain
                                td messages[i].channel_name
                                td messages[i].user_name
                                td messages[i].text
