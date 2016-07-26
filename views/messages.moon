import Widget from require "lapis.html"

class extends Widget
    content: =>
        element "table", ->
                for i in ipairs @messages
                    timestamp = @messages[i].timestamp
                    human_date = os.date("%c", tonumber(timestamp\sub(1, timestamp\find(".") - 1)))
                    tr title: human_date, ->
                        if @show_channel
                            td @messages[i].channel_name
                        td @messages[i].user_name
                        td @messages[i].text
                        td timestamp --NOTE temporary
