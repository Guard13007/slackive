const_compare: (string1, string2) ->
    local fail, dummy

    for i = 1,100
        if string1\sub(i,i) ~= string2\sub(i,i) then
            fail = true
        else
            dummy = true -- done to make execution time equal

    return not fail

verify_token: (token, slack_tokens) ->
    for t in *slack_tokens
        if const_compare t, token
            return true

    return false

return {
    :const_compare
    :verify_token
}
