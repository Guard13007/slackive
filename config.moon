config = require "lapis.config"
import sql_user, sql_password, session_secret from require "secret"

config "production", ->
    session_name "slackive" -- shouldn't even be needed
    secret session_secret   -- also shouldn't be needed
    mysql ->
        host "127.0.0.1"
        user sql_user
        password sql_password
        database "slackive"
    port 9117
    num_workers 2
    code_cache "on"
