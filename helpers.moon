import slack_tokens from require "secret"

const_compare: (string1, string2) ->
    local fail, dummy

    for i = 1,100
        if string1\sub(i,i) ~= string2\sub(i,i) then
            fail = true
        else
            dummy = true -- done to make execution time equal

    return not fail

verify_token: (token) ->
    success = false

    for t in *slack_tokens
        success = const_compare(t, token) or success

    return success

return {
    :const_compare
    :verify_token
}
