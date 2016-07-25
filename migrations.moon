import create_table, types from require "lapis.db.schema"

{
    [1]: =>
        create_table "messages", {
            {"id", types.id primary_key: true} -- NOTE id type is for MySQL ONLY
            {"team_id", types.varchar}
            {"team_domain", types.text}
            {"channel_id", types.varchar}
            {"channel_name", types.text}
            {"timestamp", types.varchar unique: true}
            {"user_id", types.varchar}
            {"user_name", types.text}
            {"text", types.text}
        }

    [2]: =>
        create_table "users", {
            {"id", types.id primary_key: true}
            {"salt", types.text}
            {"digest", types.digest}

            {"perm_view", types.boolean default: false}
        }
}

-- Example from slack:
--token=7LohdXbdnv3EaqMXNWnmdDri
--team_id=T0001
--team_domain=example
--channel_id=C2147483705
--channel_name=test
--timestamp=1355517523.000005
--user_id=U2147483697
--user_name=Steve
--text=googlebot: What is the air-speed velocity of an unladen swallow?
--trigger_word=googlebot:
