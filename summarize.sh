#!/bin/bash
set -euo pipefail

jq <<<"$(find data -name '*.json' ! -name 'index.json' -exec jq '.' "{}" \;)" \
    -s -r \
    '
        [
            "Start date",
            "Job req ID",
            "Title",
            "Time type",
            "Salary range",
            "External URL"
        ],
        (
            sort_by(.jobPostingInfo.startDate + .jobPostingInfo.jobReqId) |
            .[] |
            [
                .jobPostingInfo.startDate,
                .jobPostingInfo.jobReqId,
                .jobPostingInfo.title,
                .jobPostingInfo.timeType,
                (.jobPostingInfo.jobDescription | capture("(?<salary>\\$[\\d,]+(\\s*-\\s*\\$[\\d,]+)?)") | .salary),
                .jobPostingInfo.externalUrl
            ]
        ) |
        @csv
    ' >data/summary.csv
