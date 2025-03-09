#!/bin/bash

# Check if TELEGRAM_BOT_TOKEN is set as an environment variable, otherwise use the default
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
else
    BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
fi

# Use the second argument as the chat ID if provided, otherwise use a default
if [ $# -gt 1 ]; then
    CHAT_ID="$2"
else
    CHAT_ID="YOUR_CHAT_ID"
fi

# Use the first argument as the message if provided, otherwise use a default message
if [ $# -gt 0 ]; then
    MESSAGE="$1"
else
    MESSAGE="Hello, this is a test message from the bot!"
fi

# Send message to Telegram
curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE"