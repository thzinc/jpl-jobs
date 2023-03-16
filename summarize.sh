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
            "Salary min",
            "Salary max",
            "TS/SCI?",
            "External URL"
        ],
        (
            sort_by(.jobPostingInfo.startDate + .jobPostingInfo.jobReqId) |
            .[] |
            .jobPostingInfo + 
                (.jobPostingInfo.jobDescription | capture("(?<salaryRange>\\$(?<salaryFrom>[\\d,]+)(\\s*-\\s*\\$(?<salaryTo>[\\d,]+))?)")) +
                {
                    tsSci: [
                        [
                            .jobPostingInfo.title,
                            .jobPostingInfo.jobDescription
                        ] |
                        .[] |
                        test("\\b(ts|sci)\\b"; "i")
                    ] |
                    any
                } |
            [
                .startDate,
                .jobReqId,
                .title,
                .timeType,
                .salaryRange,
                .salaryFrom,
                .salaryTo,
                .tsSci,
                .externalUrl
            ]
        ) |
        @csv
    ' >data/summary.csv
