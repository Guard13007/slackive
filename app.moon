-- 🍕

lapis = require "lapis"
config = require("lapis.config").get!

import respond_to, json_params from require "lapis.application"
import slack_hook, error_channel, bot_name from require "secret"
import verify_token from require "helpers"

Messages = require "models.Messages"

class extends lapis.Application
    [githook: "/githook"]: respond_to {
        GET: =>
            return status: 405 --Method Not Allowed

        POST: json_params =>
            unless config.githook
                return status: 401 --Unauthorized

            if @params.ref == nil
                return { json: { status: "invalid request" } }, status: 400 --Bad Request

            if @params.ref == "refs/heads/master"
                os.execute "echo \"Updating server...\" >> logs/updates.log"
                result = 0 == os.execute "git pull origin >> logs/updates.log"
                result and= 0 == os.execute "moonc . 2>> logs/updates.log"
                result and= 0 == os.execute "lapis migrate production >> logs/updates.log"
                result and= 0 == os.execute "lapis build production >> logs/updates.log"
                if result
                    return { json: { status: "successful", message: "server updated to latest version" } }
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
            unless verify_token @params.token
                return status: 401 --Unauthorized

            if config.verbose
                human_date = os.date("%c", tonumber(@params.timestamp\sub(1, @params.timestamp\find(".") - 1)))
                os.execute "curl -X POST --data-urlencode 'payload={\"channel\": \"#slackiver\", \"username\": \"The Slackiver\", \"text\": \"*Saving message from @#{@params.user_name} (#{@params.user_id}) on #{@params.team_domain}.slack.com (#{@params.team_id}):*\\n#{@params.text\gsub("\\", "\\\\")\gsub("'", "’")\gsub("\"", "\\\"")}\\n*[Sent #{human_date} in ##{@params.channel_name} (#{@params.channel_id})]*\", \"icon_emoji\": \":information_source:\"}' #{slack_hook}"

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
                human_date = os.date("%c", tonumber(@params.timestamp\sub(1, @params.timestamp\find(".") - 1)))
                os.execute "curl -X POST --data-urlencode 'payload={\"channel\": \"#slackiver\", \"username\": \"The Slackiver\", \"text\": \"*Error saving message from @#{@params.user_name} (#{@params.user_id}) on #{@params.team_domain}.slack.com (#{@params.team_id}):*\\n#{@params.text\gsub("\\", "\\\\")\gsub("'", "’")\gsub("\"", "\\\"")}\\n*[Sent #{human_date} in ##{@params.channel_name} (#{@params.channel_id})]*\", \"icon_emoji\": \":warning:\"}' #{slack_hook}"
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

    [test: "/test"]: =>
        verify_token "wowshit"
        return status: 200
