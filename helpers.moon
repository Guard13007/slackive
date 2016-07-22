import slack_hook, error_channel, bot_name from require "secret"

const_compare: (string1, string2) ->
    local fail, dummy

    for i = 1,100
        if string1\sub(i,i) ~= string2\sub(i,i) then
            fail = true
        else
            dummy = true -- done to make execution time equal

    return not fail

msg_slack: (msg, emoji=":warning:") ->
    os.execute "curl -X POST --data-urlencode 'payload={\"channel\": \"#{error_channel}\", \"username\": \"#{bot_name}\", \"text\": \"#{msg}\", \"icon_emoji\": \"#{emoji}\"}' #{slack_hook}"

return {
    :const_compare
    :msg_slack
}
