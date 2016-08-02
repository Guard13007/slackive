html = require "lapis.html"

class extends html.Widget
    content: =>
        html_5 ->
            head ->
                title @title or "Slackiver"
                link rel: "stylesheet", href: @build_url "static/css/pure-min.css"
                link rel: "stylesheet", href: @build_url "static/css/slackiver.css"
                --script src: @build_url "static/js/jquery-3.1.0.min.js"
            body ->
                @content_for "inner"

                div class: "footer", ->
                    if @session.id
                        a href: @url_for("modify_user"), "modify user"
                        text " | "
                        a href: @url_for("logout"), "log out"
                    else
                        a href: @url_for("create_user"), "make account"
                        text " | "
                        a href: @url_for("login"), "sign in"
