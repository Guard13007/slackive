import slack_tokens from require "secret"

const_compare = (string1, string2) ->
    local fail, dummy

    for i = 1,100
        if string1\sub(i,i) ~= string2\sub(i,i) then
            fail = true
        else
            dummy = true -- done to make execution time equal

    return not fail

verify_token = (token) ->
    local success, dummy

    for t in *slack_tokens
        if const_compare t, token
            success = true
        else
            dummy = true -- done to make execution time equal

    return success

str_in_table = (str1, tab) ->  --@params.user_name, ignored_names
    for str2 in *tab
        if str1 == str2
            return true

    return false

return {
    :const_compare
    :verify_token
    :str_in_table
}
