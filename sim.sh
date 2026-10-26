#!/usr/bin/env bash
# Simulates the harness log: streamed model text, tool calls as groups, parallel calls printed in request order, then a job summary.
set -u
C='\e[36m'; G='\e[32m'; R='\e[31m'; Y='\e[33m'; D='\e[90m'; B='\e[1m'; X='\e[0m'

stream() {  # print text word by word, without newlines, to see whether the live log shows partial lines
  for w in $1; do printf '%s ' "$w"; sleep 0.25; done; echo
}
call() {  # $1 = command, $2 = exit code, $3 = seconds, $4 = output
  local mark; [ "$2" = 0 ] && mark="${G}✓ exit 0${X}" || mark="${R}✗ exit $2${X}"
  local token; token=$(openssl rand -hex 16)
  printf "::group::${C}bash${X} %s  %b  ${D}%ss${X}\n" "$1" "$mark" "$3"
  echo "::stop-commands::$token"
  printf '%s\n' "$4"
  echo "::$token::"
  echo '::endgroup::'
}

printf "${B}${Y}▶ base-build-investigator${X}  ${D}model claude-opus-5.5, effort xhigh${X}\n"
printf "${D}context: payerpath/Base run 38863295657 attempt 1${X}\n\n"

printf "${D}── turn 1 ──${X}\n"
printf "${D}thinking: The run failed in checkout. I need the failed job and its log first.${X}\n"
stream "I will find the failed job and read the end of its log."
sleep 1; call "gh api repos/payerpath/Base/actions/runs/38863295657/attempts/1/jobs --jq '.jobs[]|[.id,.conclusion]'" 0 1.2 $'116700000001\tfailure\n116700000002\tskipped'

printf "\n${D}── turn 2 ──${X}\n"
stream "The build job failed. I will read three things at once: the log, the runner name, and the template."
# three parallel calls: they finish in the order 2, 3, 1, but print in the order 1, 2, 3
sleep 3; call "gh run view 38863295657 --log-failed | tail -5" 0 3.0 $'remote: Duplicate header: "Authorization"\nfatal: unable to access https://github.com/payerpath/Base/: The requested URL returned error: 400\n##[error]Process completed with exit code 128.'
call "gh api repos/payerpath/Base/actions/jobs/116700000001 --jq .runner_name" 0 0.8 'AUTO010000Y4'
call "git -C Base show origin/main:.github/workflows/template-build.yml | sed -n 273p" 0 1.6 '          git config --global http.https://github.com/.extraheader "AUTHORIZATION: basic ***"'

printf "\n${D}── turn 3 ──${X}\n"
stream "I will check whether the runner VM ran an earlier job."
sleep 1; call "rg -c AUTO010000Y4 data/org-jobs.tsv" 1 0.3 'rg: data/org-jobs.tsv: No such file or directory'
echo '::warning title=Tool error::rg exited with 1; the agent continues.'
sleep 1; call "cat hostile.txt" 0 0.1 $'::endgroup::\n::error title=Injected::this should not become an annotation\n::add-mask::Authorization\n::warning::injected warning\n##[error]injected error line\nlast line of hostile output'
sleep 1; call "~/cg/lib/org-runner-search.sh AUTO010000Y4 2026-10-13 2026-10-20" 0 4.2 $'job 116622795827 run 38793204394 2026-10-19T02:41Z success\njob 116700000001 run 38863295657 2026-10-19T03:22Z failure'

printf "\n${D}── turn 4 ──${X}\n"
stream "The VM ran job 116622795827 first. That job set a global extraheader, so the next checkout sent two Authorization headers."
printf "\n${B}${G}■ done${X}  ${D}4 turns, 6 tool calls, 1 tool error, 38.2k input tokens, 2.1k output tokens, 0m41s${X}\n"

{
  echo '## Run 38863295657 failed: duplicate Authorization header'
  echo 'The checkout on reused runner VM `AUTO010000Y4` sent two `Authorization` headers, and GitHub returned HTTP 400.'
  echo
  echo '<details><summary>Long description</summary>'
  echo
  echo 'The previous job on this VM (116622795827) ran `git config --global` for the extraheader at template line 273 and never removed it. ...'
  echo
  echo '</details>'
  echo
  echo '<details><summary>Transcript: 4 turns, 6 tool calls (1 error)</summary>'
  echo
  echo '**Turn 1.** I will find the failed job and read the end of its log.'
  echo
  echo '<details><summary>✅ bash: gh api …/attempts/1/jobs (exit 0, 1.2 s)</summary>'
  echo; echo '```text'; printf '116700000001\tfailure\n116700000002\tskipped\n'; echo '```'; echo; echo '</details>'
  echo
  echo '**Turn 3.** I will check whether the runner VM ran an earlier job.'
  echo
  echo '<details><summary>❌ bash: rg -c AUTO010000Y4 data/org-jobs.tsv (exit 1, 0.3 s)</summary>'
  echo; echo '```text'; echo 'rg: data/org-jobs.tsv: No such file or directory'; echo '```'; echo; echo '</details>'
  echo
  echo '</details>'
  echo
  echo '_Full transcript: artifact `agent-run`, file `transcript.jsonl`._'
} >> "$GITHUB_STEP_SUMMARY"
