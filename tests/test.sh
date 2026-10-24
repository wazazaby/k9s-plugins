#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

cat > "$test_dir/kubectl" <<'SH'
#!/bin/sh
case "$*" in
  *"get pod web-abc -o json")
    printf '%s\n' '{"metadata":{"ownerReferences":[{"controller":true,"kind":"ReplicaSet","name":"web-rs","uid":"rs-uid"}]}}' ;;
  *"get pod db-0 -o json")
    printf '%s\n' '{"metadata":{"ownerReferences":[{"controller":true,"kind":"StatefulSet","name":"db","uid":"db-uid"}]}}' ;;
  *"get replicaset web-rs -o json")
    printf '%s\n' '{"metadata":{"ownerReferences":[{"controller":true,"kind":"Deployment","name":"web","uid":"deploy-uid"}]}}' ;;
  *"get job backup-123 -o json")
    printf '%s\n' '{"metadata":{"ownerReferences":[{"controller":true,"kind":"CronJob","name":"backup","uid":"cron-uid"}]}}' ;;
  *"get job standalone -o json")
    printf '%s\n' '{"metadata":{}}' ;;
  *"get deployments web -o json")
    printf '%s\n' '{"kind":"Deployment","spec":{"selector":{"matchLabels":{"app":"web"},"matchExpressions":[{"key":"tier","operator":"In","values":["api","front"]}]}}}' ;;
  *"get statefulsets db -o json")
    printf '%s\n' '{"kind":"StatefulSet","spec":{"selector":{"matchLabels":{"app":"db"}}}}' ;;
  *) printf 'Unexpected kubectl call: %s\n' "$*" >&2; exit 2 ;;
esac
SH

cat > "$test_dir/pbcopy" <<'SH'
#!/bin/sh
cat > "$K9S_TEST_CLIPBOARD"
SH

chmod +x "$test_dir/kubectl" "$test_dir/pbcopy"
export PATH="$test_dir:$PATH"
export K9S_TEST_CLIPBOARD="$test_dir/clipboard"

copy_query() {
  "$repo_root/bin/k9s-copy-workload-view" demo test "$1" "$2"
  /bin/bash -n "$K9S_TEST_CLIPBOARD"
  cat "$K9S_TEST_CLIPBOARD"
}

expect_query() {
  local actual
  actual=$(copy_query "$2" "$3")
  if [[ $actual != "$1" ]]; then
    printf 'Expected: %s\nActual:   %s\n' "$1" "$actual" >&2
    exit 1
  fi
}

expect_query 'kubectl --context demo -n test get deployments' deployments web
expect_query "kubectl --context demo -n test get pods -l 'app=web,tier in (api,front)'" pods web-abc
expect_query "kubectl --context demo -n test get pods -l 'app=db'" pods db-0
expect_query "kubectl --context demo -n test get replicasets -l 'app=web,tier in (api,front)'" replicasets web-rs
expect_query 'kubectl --context demo -n test get jobs' jobs standalone

job_query=$(copy_query jobs backup-123)
if [[ $job_query != *'--arg uid cron-uid'* || $job_query != *'xargs -r kubectl --context demo -n test get job' ]]; then
  printf 'Unexpected CronJob query: %s\n' "$job_query" >&2
  exit 1
fi

mkdir "$test_dir/linux"
cat > "$test_dir/linux/wl-copy" <<'SH'
#!/bin/sh
/bin/cat > "$K9S_TEST_CLIPBOARD"
SH
chmod +x "$test_dir/linux/wl-copy"
ln -s /bin/bash "$test_dir/linux/bash"
PATH="$test_dir/linux" "$repo_root/bin/k9s-copy-workload-view" demo test deployments web
if [[ $(cat "$K9S_TEST_CLIPBOARD") != 'kubectl --context demo -n test get deployments' ]]; then
  printf 'Linux clipboard fallback failed.\n' >&2
  exit 1
fi

printf 'All offline checks passed.\n'
