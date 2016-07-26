lapis = require "lapis"
csrf = require "lapis.csrf"
config = require("lapis.config").get!

crypto = require "crypto"
bcrypt = require "bcrypt"

import respond_to from require "lapis.application"

Users = require "models.Users"

class extends lapis.Application
    [create_user: "/create_user"]: respond_to {
        GET: =>
            if @session.id
                return redirect_to: @url_for "index"

            csrf_token = csrf.generate_token @
            @html ->
                form {
                    action: "/create_user"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Username: "
                    input type: "text", name: "user"
                    p "Password: "
                    input type: "password", name: "password"
                    br!
                    input type: "hidden", name: "csrf_token", value: csrf_token
                    input type: "submit"

        POST: =>
            csrf.assert_token @
            if #@params.password < 8
                return "Your password must be at least 8 characters long."

            salt = crypto.pkey.generate("rsa", 4096)\to_pem!
            digest = bcrypt.digest @params.password .. salt, config.digest_rounds

            user, errMsg = Users\create {
                name: @params.user
                salt: salt
                digest: digest
            }

            if user
                @session.id = user.id
                return redirect_to: @url_for "index"
            else
                return errMsg
    }

    [login: "/login"]: respond_to {
        GET: =>
            if @session.id
                return redirect_to: @url_for "index"

            csrf_token = csrf.generate_token @
            @html ->
                form {
                    action: "/login"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Username: "
                    input type: "text", name: "user"
                    p "Password: "
                    input type: "password", name: "password"
                    br!
                    input type: "hidden", name: "csrf_token", value: csrf_token
                    input type: "submit"

        POST: =>
            csrf.assert_token @
            if user = Users\find name: @params.user
                if bcrypt.verify @params.password .. user.salt, user.digest
                    @session.id = user.id

            return redirect_to: @url_for "index"
    }

    [logout: "/logout"]: =>
        @session.id = nil
        return redirect_to: @url_for "index"
