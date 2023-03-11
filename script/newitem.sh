#!/bin/bash

cd /config/*

# TMDB API endpoint and API Key
TMDB_API="https://api.themoviedb.org/3"
API_KEY="*"

# Telegram API endpoint and chat ID
TELEGRAM_API="https://api.telegram.org/bot*/sendPhoto"
CHAT_ID="*"

# TMDB movie or TV ID and content format
TMDB_ID="$1"
CONTENT_FORMAT="$2"

# Check if script is already running for this TMDB ID
LOCKFILE="/tmp/${TMDB_ID}.lock"
if [[ -e $LOCKFILE ]]; then
  CREAT_TINE=`stat -c %W "/tmp/${TMDB_ID}.lock"`
  CURRENT_TIME=`date +%s`
  let TIME_PAST=${CURRENT_TIME}-${CREAT_TINE}
  if [[ ${TIME_PAST} -lt 3600 ]] ; then
      echo "`date +%s` Error: Script had already run for TMDB ID ${TMDB_ID} in the past 1 hour. Exiting." >> newitem.log
      exit 1
  else
      rm /tmp/${TMDB_ID}.lock
      touch /tmp/${TMDB_ID}.lock
  fi
fi

# Create lockfile for this TMDB ID
touch $LOCKFILE

# Get movie or TV details from TMDB API
if [[ $CONTENT_FORMAT == "Movie" ]]; then
  DETAILS_URL="${TMDB_API}/movie"
  CONTENT_FORMATUSER=Movie
else
  DETAILS_URL="${TMDB_API}/tv"
  CONTENT_FORMATUSER=TV
fi
MOVIE_DETAILS=$(curl -s "${DETAILS_URL}/${TMDB_ID}?api_key=${API_KEY}&language=zh-CN")

# Parse movie or TV details using jq command
MOVIE_TITLE=$(echo "$MOVIE_DETAILS" | jq -r '.title // .name')
MOVIE_POSTER_PATH=$(echo "$MOVIE_DETAILS" | jq -r '.poster_path')

# Download movie or TV poster image from TMDB API
POSTER_URL="https://image.tmdb.org/t/p/original${MOVIE_POSTER_PATH}"
curl -s "$POSTER_URL" -o "${TMDB_ID}.jpg"

# Generate message text with movie or TV details and timestamp
CURRENT_TIME=$(date +%s)
MESSAGE_TEXT="#${CONTENT_FORMATUSER}更新

#${MOVIE_TITLE}"

# Send message text and photo to Telegram
curl -s -X POST "${TELEGRAM_API}" \
  -F "chat_id=${CHAT_ID}" \
  -F "caption=${MESSAGE_TEXT}" \
  -F "photo=@${TMDB_ID}.jpg" \
  -F "parse_mode=Markdown"

# Remove photo for this TMDB ID
rm ${TMDB_ID}.jpg
echo "`date +%s` ${TMDB_ID} 成功发送通知!" >> newitem.log
