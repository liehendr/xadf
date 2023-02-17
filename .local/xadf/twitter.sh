#!/bin/bash
# This is constructed based from:
# https://www.reddit.com/r/DataHoarder/comments/yy8o9w/for_everyone_using_gallerydl_to_backup_twitter/

ggcraftcfg(){

ggcfgdir="$HOME/.config/gallery-dl"
ytua="$ggcfgdir/ytua"

if [ ! -d "$ggcfgdir" ]
then
  echo "[ggcraftcfg]: no config dir is present, creating directory"
  mkdir "$ggcfgdir"
fi

if [ ! -f $ytua ]
then
  echo "[ggcraftcfg]: no ua file is present, downloading first"
  ggcraftcfgorigpwd=$PWD
  cd $ggcfgdir
  wget -c https://raw.xenomancy.id/agents/ytua
  cd $ggcraftcfgorigpwd
fi

echo "[ggcraftcfg]: Constructing configuration file \$HOME/.config/xadf/twitter.cfg"
cat <<EOF > $HOME/.config/xadf/twitter.cfg
#!/bin/bash
## Configuration file for ggcraft

# To set up environment value of ggua, adjust it to your preferred user agents
export ggua="\$(cat ~/.config/gallery-dl/ytua)"

# For base directory of all downloads by gg function (the twitter extractor)
export ggbasedir="~/Pictures/gallery-dl"

# You can supply the cookie like the following
# export ggcookies="[\"<your browser (firefox, chromium, etc)>\"]"
# ex:
# export ggcookies="[\"firefox\"]"
export ggcookies="null"

# Where to store the configuration file
export ggcfg="\$HOME/.config/gallery-dl/config.json"

EOF
}

# Source twitter.cfg so we can construct config.json
[ ! -f $HOME/.config/xadf/twitter.cfg ] && ggcraftcfg
source $HOME/.config/xadf/twitter.cfg

gg(){
gallery-dl -c "$ggcfg" --write-metadata $@
}

ggcraft(){
cat <<EOF > "$ggcfg"
{
    "extractor":{
        "#": "you can supply the cookie like the following",
        "#": ["<your browser (firefox, chromium, etc)>"],
        "cookies": $ggcookies,
        "#": "you can supply the base dir like the following",
        "#": "~/Pictures/gallery-dl/",
        "base-directory": "$ggbasedir",
        "user-agent": "$ggua",
        "skip": true,
        "twitter":{
            "users": "https://twitter.com/{legacy[screen_name]}",
            "text-tweets":true,
            "quoted":true,
            "retweets":true,
            "logout":true,
            "replies":true,
            "filename": "twitter_{author[name]}_{tweet_id}_{num}.{extension}",
            "directory":{
                "quote_id   != 0": ["twitter", "{quote_by}"  , "quote-retweets"],
                "retweet_id != 0": ["twitter", "{user[name]}", "retweets"  ],
                ""               : ["twitter", "{user[name]}"              ]
            },
            "postprocessors":[
                {"name": "metadata", "event": "post", "filename": "twitter_{author[name]}_{tweet_id}_main.json"}
            ]
        }
    }
}
EOF
}

ggtake(){
# Make a file to put twittwr links on,
# sanitize it, load to input, and remove
# the file
GGTAKE="$HOME/.GGTAKE_EDIT"
nano $GGTAKE
# remove all contents from the first question mark
# to the end of line
sed -i 's/?.*$//' $GGTAKE
# load to input stack, assuming stack.sh is loaded
stack read $GGTAKE
rm $GGTAKE
}

# stage input into file and shift contents
# of special stacks to alpha
ggstager(){
stack write input input.do
stack mv beta alpha
stack mv gamma beta
stack mv input gamma
stack save twdl
}
