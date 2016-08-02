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

                hr!
                div class: "footer", ->
                    if @session.id
                        a class: "pure-button", href: @url_for("user_edit"), "modify user"
                        text " "
                        a class: "pure-button", href: @url_for("user_logout"), "log out"
                    else
                        a class: "pure-button", href: @url_for("user_new"), "make account"
                        text " "
                        a class: "pure-button", href: @url_for("user_login"), "sign in"
