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
Users = require "users.models.Users"

class extends lapis.Application
    layout: "layout"

    @include "githook/githook"
    @include "users/users"

    [incoming: "/incoming"]: respond_to {
        GET: =>
            return status: 405, "Method Not Allowed"

        POST: json_params =>
            unless verify_token @params.token
                return status: 401, "Unauthorized"

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
        @html ->
            p "Welcome to Slackiver."
            --TODO have actual useful stuff here if someone is logged in

    [all: "/all(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view == 1
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "ORDER BY timestamp ASC", per_page: 50
                --if page > Paginator\num_pages!
                --    return redirect_to: @url_for "all", page: Paginator\num_pages!

                @show_channel = true
                @messages = Paginator\get_page page
                return render: "messages"

        return status: 401, "Unauthorized"

    [name_message_list: "/:team_domain/:channel_name(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view == 1
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "WHERE team_domain = ? AND channel_name = ? ORDER BY timestamp ASC", @params.team_domain, @params.channel_name, per_page: 50
                --if page > Paginator\num_pages!
                --    return redirect_to: @url_for "name_message_list", team_domain: @params.team_domain, channel_name: @params.channel_name, page: Paginator\num_pages!

                @messages = Paginator\get_page page
                return render: "messages"

        return status: 401, "Unauthorized"

    [id_message_list: "/id/:team_id/:channel_id(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view == 1
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "WHERE team_id = ? AND channel_id = ? ORDER BY timestamp ASC", @params.team_id, @params.channel_id, per_page: 50
                --if page > Paginator\num_pages!
                --    return redirect_to: @url_for "id_message_list", team_id: @params.team_id, channel_id: @params.channel_id, page: Paginator\num_pages!

                @messages = Paginator\get_page page
                return render: "messages"

        return status: 401, "Unauthorized"

    [short_name_message_list: "/:channel_name(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view == 1
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "WHERE channel_name = ? ORDER BY timestamp ASC", @params.channel_name, per_page: 50
                --if page > Paginator\num_pages!
                --    return redirect_to: @url_for "short_name_message_list", channel_name: @params.channel_name, page: Paginator\num_pages!

                @messages = Paginator\get_page page
                return render: "messages"

        return status: 401, "Unauthorized"

    [short_id_message_list: "/id/:channel_id(/:page[%d])"]: =>
        if @session.id
            user = Users\find id: @session.id
            if user.perm_view == 1
                page = tonumber(@params.page) or 1

                Paginator = Messages\paginated "WHERE channel_id = ? ORDER BY timestamp ASC", @params.channel_id, per_page: 50
                --if page > Paginator\num_pages!
                --    return redirect_to: @url_for "short_id_message_list", channel_id: @params.channel_id, page: Paginator\num_pages!

                @messages = Paginator\get_page page
                return render: "messages"

            return status: 401, "Unauthorized"
