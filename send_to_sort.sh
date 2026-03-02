#!/usr/bin/env bash

# determine route
KEY="${1:-}"
JSON_FILE="${2:-./example.json}"

if [[ -z "$KEY" ]]; then
    echo "Error: missing key (sort or compile)"
    echo "Usage: $0 <sort|compile> [json-file]"
    kill $ERL_PID
    exit 1
fi

case "$KEY" in
    sort)
        ROUTE="/api/job/sort-tasks";
        ;;
    compile)
        ROUTE="/api/job/compile-command";
        ;;
    *)
        echo "Unknown key: $KEY" >&2
        echo "Valid keys are \"sort\" and \"compile\"." >&2
        exit 1
        ;;
esac

# perform the POST request
curl -X POST "http://localhost:8080$ROUTE" \
     -H "Content-Type: application/json" \
     --data-binary "@$JSON_FILE"


exit 0
