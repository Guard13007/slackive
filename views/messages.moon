import Widget from require "lapis.html"

class extends Widget
    content: =>
        element "table", ->
                for i in ipairs @messages
                    tr ->
                        td @messages[i].timestamp
                        td @messages[i].team_domain
                        td @messages[i].channel_name
                        td @messages[i].user_name
                        td @messages[i].text
