#!/bin/bash
set -euo pipefail

BASE_URL=https://citjpl.wd5.myworkdayjobs.com
JOBS_URL=$BASE_URL/wday/cxs/citjpl/Jobs
LIMIT=20
OFFSET=0

jobPostings() {
    jq -s <<<"$(
        while :; do
            REQUEST_BODY=$(
                echo '{}' |
                    jq \
                        --arg limit "$LIMIT" \
                        --arg offset "$OFFSET" \
                        '{ limit: $limit, offset: $offset }'
            )

            RESPONSE_BODY=$(
                curl -s -X POST "$JOBS_URL/jobs" \
                    -H "Referer: $BASE_URL/en-US/Jobs" \
                    -H "Origin: $BASE_URL" \
                    -H 'Accept: application/json' \
                    -H 'Accept-Encoding: gzip, deflate, br' \
                    -H "$COOKIE_HEADER" \
                    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/110.0' \
                    -H 'Accept-Language: en-US' \
                    -H 'Content-Type: application/json' \
                    -H 'X-CALYPSO-CSRF-TOKEN: 70fa28d0-424b-4004-8790-15da5c60f57d' \
                    -H 'Connection: keep-alive' \
                    -H 'Sec-Fetch-Dest: empty' \
                    -H 'Sec-Fetch-Mode: cors' \
                    -H 'Sec-Fetch-Site: same-origin' \
                    -H 'DNT: 1' \
                    -H 'Sec-GPC: 1' \
                    -d @- <<<"$REQUEST_BODY" |
                    gunzip |
                    jq
            )

            jq <<<"$RESPONSE_BODY" \
                '.jobPostings[]'

            TOTAL=$(jq <<<"$RESPONSE_BODY" \
                -r \
                '.total')

            if ((OFFSET < TOTAL)); then
                OFFSET=$((OFFSET + 20))
            else
                exit 0
            fi
        done
    )"
}

jobPosting() {
    curl -s -X GET "${JOBS_URL}${1}" \
        -H "Referer: ${JOBS_URL}${1}" \
        -H 'Accept: application/json' \
        -H 'Accept-Encoding: gzip, deflate, br' \
        -H "$COOKIE_HEADER" \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/110.0' \
        -H 'Accept-Language: en-US' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -H 'X-CALYPSO-CSRF-TOKEN: 70fa28d0-424b-4004-8790-15da5c60f57d' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: same-origin' \
        -H 'DNT: 1' \
        -H 'Sec-GPC: 1' |
        gunzip |
        jq
}

JOB_POSTINGS=$(jobPostings)

rm -rf data/
mkdir -p data/
cat <<<"$JOB_POSTINGS" >data/index.json
jq <<<"$JOB_POSTINGS" \
    -r \
    '.[].externalPath' |
    while read -r EXTERNAL_PATH; do
        FILENAME="${EXTERNAL_PATH//\//-}.json"
        jobPosting "$EXTERNAL_PATH" >"data/$FILENAME"
    done
