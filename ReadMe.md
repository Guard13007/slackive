# Slackiver

Or *Slack-Archiver*, whatever. Basically, set up outgoing hooks on Slack, an
incoming hook to monitor for errors, and this, and all messages can be stored in
a database.

## Installation

On Ubuntu or Debian? You should be able to just:

```bash
git clone https://github.com/Guard13007/slackiver.git
cd slackiver
chmod +x ./install.sh
./install.sh
```

If you can't or are using another OS, look at the script to see how it works.
Also, note that the server will be running on port 9443, so you should set up a
proxy to it if you want it on 443.
