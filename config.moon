config = require "lapis.config"
import sql_user, sql_password, session_secret, ssl_cert, ssl_key from require "secret"

config {"production", "development"}, ->
    session_name "slackiver" -- shouldn't even be needed
    secret session_secret    -- also shouldn't be needed
    mysql ->
        host "127.0.0.1"
        user sql_user
        password sql_password
    port 9443
    num_workers 2
    cert ssl_cert
    cert_key ssl_key

config "production", ->
    code_cache "on"
    mysql ->
        database "slackiver"

config "development", ->
    debug true
    code_cache "off"
    mysql ->
        database "slackiver-dev"
