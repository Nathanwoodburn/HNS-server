#!/bin/bash
KEY="<REPLACE WITH YOUR API KEY>"
DISCORD="<REPLACE WITH A DISCORD WEBHOOK URL>"
BLOCK=$(hsd-cli info --url=127.0.0.1 --api-key=$KEY | jq '.chain.height')
INBOUND=$(hsd-cli info --url=127.0.0.1 --api-key=$KEY | jq '.pool.inbound')
TYPES=$(hsd-cli rpc getpeerinfo --url=127.0.0.1 --api-key=$KEY | jq '. | map(.subver) | group_by(.) | map({key:.[0], value: length}) | sort_by(.key) | from_entries + {total: [.[].value] | add}')
URL="$(hsd-cli rpc getpeerinfo --url=127.0.0.1 --api-key=$KEY | jq -r '.[]|select(.inbound==true)|.addr|sub(":.*$";"")' | curl -s -XPOST --data-binary @- "ipinfo.io/tools/summarize-ips?cli=1"|jq -r .reportUrl)"
CLEANED=$(echo $TYPES | sed 's/.*{\(.*\)}.*$/\1/')
CLEANED=$(echo $CLEANED | sed 's/"/ /g')
CLEANED=$(echo $CLEANED | sed 's/,/\\n /g')
JSON="{\"content\": \"Current Height: $BLOCK\nUsers connected to node: $INBOUND\",\"embeds\": [{\"title\": \"Current Connections\",\"description\": \"$CLEANED\",\"url\": \"$URL\",\"color\": null,\"footer\": {\"text\": \"PS click the title to get a map of connections\"}}],\"attachments\": []}"
curl -H "Content-Type: application/json" -X POST -d "$JSON" $DISCORD