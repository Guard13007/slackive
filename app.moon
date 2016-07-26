-- 🍕

lapis = require "lapis"
csrf = require "lapis.csrf"
config = require("lapis.config").get!

crypto = require "crypto"
bcrypt = require "bcrypt"

import respond_to, json_params from require "lapis.application"
import slack_hook, error_channel, bot_name from require "secret"
import verify_token from require "helpers"

Messages = require "models.Messages"
Users = require "models.Users"

class extends lapis.Application
    layout: "layout"

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
            return status: 405 --Method Not Allowed

        POST: json_params =>
            unless verify_token @params.token
                return status: 401 --Unauthorized

            if config.verbose and not @params.user_name == "slackbot"
                human_date = os.date("%c", tonumber(@params.timestamp\sub(1, @params.timestamp\find(".") - 1)))
                os.execute "curl -X POST --data-urlencode 'payload={\"channel\": \"#{error_channel}\", \"username\": \"#{bot_name}\", \"text\": \"*Saving message from @#{@params.user_name} (#{@params.user_id}) on #{@params.team_domain}.slack.com (#{@params.team_id}):*\\n#{@params.text\gsub("\\", "\\\\")\gsub("'", "’")\gsub("\"", "\\\"")}\\n*[Sent #{human_date} in ##{@params.channel_name} (#{@params.channel_id})]*\", \"icon_emoji\": \":information_source:\"}' #{slack_hook}"

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

            if not message and not @params.user_name == "slackbot"
                human_date = os.date("%c", tonumber(@params.timestamp\sub(1, @params.timestamp\find(".") - 1)))
                os.execute "curl -X POST --data-urlencode 'payload={\"channel\": \"#{error_channel}\", \"username\": \"#{bot_name}\", \"text\": \"*Error saving message from @#{@params.user_name} (#{@params.user_id}) on #{@params.team_domain}.slack.com (#{@params.team_id}):*\\n#{@params.text\gsub("\\", "\\\\")\gsub("'", "’")\gsub("\"", "\\\"")}\\n*[Sent #{human_date} in ##{@params.channel_name} (#{@params.channel_id})]*\", \"icon_emoji\": \":warning:\"}' #{slack_hook}"
    }

    [index: "/"]: =>
        @html -> p "Welcome to Slackiver."
        --TODO have actual useful stuff here if someone is logged in

    [create_user: "/create_user"]: respond_to {
        GET: =>
            if @session.id
                return redirect_to: @url_for "index"

            csrf_token = csrf.generate_token @
            @html ->
                form {
                    action: "/create_user"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Username: "
                    input type: "text", name: "user"
                    p "Password: "
                    input type: "password", name: "password"
                    br!
                    input type: "hidden", name: "csrf_token", value: csrf_token
                    input type: "submit"

        POST: =>
            csrf.assert_token @
            if #@params.password < 8
                return "Your password must be at least 8 characters long."

            salt = crypto.pkey.generate("rsa", 4096)\to_pem!
            digest = bcrypt.digest @params.password .. salt, config.digest_rounds

            user, errMsg = Users\create {
                name: @params.user
                salt: salt
                digest: digest
            }

            if user
                @session.id = user.id
                return redirect_to: @url_for "index"
            else
                return errMsg
    }

    [login: "/login"]: respond_to {
        GET: =>
            if @session.id
                return redirect_to: @url_for "index"

            csrf_token = csrf.generate_token @
            @html ->
                form {
                    action: "/login"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Username: "
                    input type: "text", name: "user"
                    p "Password: "
                    input type: "password", name: "password"
                    br!
                    input type: "hidden", name: "csrf_token", value: csrf_token
                    input type: "submit"

        POST: =>
            csrf.assert_token @
            if user = Users\find name: @params.user
                if bcrypt.verify @params.password .. user.salt, user.digest
                    @session.id = user.id

            return redirect_to: @url_for "index"
    }

    [logout: "/logout"]: =>
        @session.id = nil
        return redirect_to: @url_for "index"

    [all: "/all(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "ORDER BY timestamp ASC", per_page: 100

                @messages = Paginator\get_page page
                return render: "messages"

        return status: 401 --Unauthorized

    [name_message_list: "/:team_domain/:channel_name(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "WHERE team_domain = ? AND channel_name = ? ORDER BY timestamp ASC", @params.team_domain, @params.channel_name, per_page: 100

                @messages = Paginator\get_page page
                render: "messages"

        return status: 401 --Unauthorized

    [id_message_list: "/id/:team_id/:channel_id(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "WHERE team_id = ? AND channel_id = ? ORDER BY timestamp ASC", @params.team_id, @params.channel_id, per_page: 100

                @messages = Paginator\get_page page
                render: "messages"

        return status: 401 --Unauthorized
