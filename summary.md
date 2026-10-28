The checkout failed because a reused runner VM still had a global `Authorization` header from the previous job. Remove the `--global` extraheader in `template-build.yml`.

The `Checkout Base repository` step failed with HTTP 400.[^1] GitHub rejected the request because it contained two `Authorization` headers.[^1] The runner VM had run another job just before this one.[^2] That job's step 29 set the header with `git config --global`.[^3]

[^1]: `gh run view 38863295657 --log-failed | tail -20`

    ```text
    remote: Duplicate header: "Authorization"
    fatal: unable to access 'https://github.com/payerpath/Base/': The requested URL returned error: 400
    ```

[^2]: `gh api repos/payerpath/Base/actions/jobs/116622795827 --jq .runner_name`

    ```text
    Ue2PrSHDAUTO01-AUTO010000Y4-20261015-115635
    ```

[^3]: `gh run view 38793204394 --log | rg 'git config --global'`

    ```text
    git config --global http.https://github.com/.extraheader "AUTHORIZATION: basic $b64"
    ```

<sub>base-build-investigator · claude-sonnet-5.5, effort high · 8 turns · 10 tool calls · 4m 47s</sub>
