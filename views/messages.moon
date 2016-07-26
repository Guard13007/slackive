import Widget from require "lapis.html"

class extends Widget
    content: =>
        element "table", ->
                for i in ipairs @messages
                    tr title: os.date("%c", tonumber(@messages[i].timestamp\sub(1, @messages[i].timestamp\find(".") - 1))), ->
                        --td @messages[i].team_domain
                        if @show_channel
                            td @messages[i].channel_name
                        td @messages[i].user_name
                        td @messages[i].text
