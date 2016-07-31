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
                if Users\count! < 2
                    user\update {
                        perm_view: 1 --true (note true/false are numbers in MySQL but boolean in PostgreSQL)
                    }
                return redirect_to: @url_for "index"
            else
                return errMsg
    }

    [modify_user: "/modify_user"]: respond_to {
        GET: =>
            unless @session.id
                return redirect_to: @url_for "index"

            csrf_token = csrf.generate_token @
            user = Users\find id: @session.id
            @html ->
                form {
                    action: "/modify_user"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Change username? "
                    input type: "text", name: "user", placeholder: user.name
                    input type: "hidden", name: "csrf_token", value: csrf_token
                    input type: "submit"
                hr!

                form {
                    action: "/modify_user"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Change password? "
                    input type: "password", name: "oldpassword"
                    input type: "password", name: "password"
                    input type: "hidden", name: "csrf_token", value: csrf_token
                    input type: "submit"
                hr!

                form {
                    action: "/modify_user"
                    method: "POST"
                    enctype: "multipart/form-data"
                }, ->
                    p "Delete user? "
                    input type: "checkbox", name: "delete"
                    input type: "hidden", name: "csrf_token", value: csrf_token
                    input type: "submit"

        POST: =>
            csrf.assert_token @
            user = Users\find id: @session.id

            if @params.user != ""
                user\update {
                    name: @params.user
                }
                return redirect_to: @url_for "index"

            elseif @params.password != ""
                if bcrypt.verify @params.oldpassword .. user.salt, user.digest
                    salt = crypto.pkey.generate("rsa", 4096)\to_pem!
                    digest = bcrypt.digest @params.password .. salt, config.digest_rounds

                    user\update {
                        salt: salt
                        digest: digest
                    }

                else
                    return status: 401, "Incorrect password."

            elseif @params.delete
                if user\delete!
                    @session.id = nil
                    return @url_for "index"   --"Your account has been deleted."
                else
                    return status: 500, "Error deleting your account."

            return redirect_to: @url_for "index"
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
