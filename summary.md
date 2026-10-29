# Summary

The checkout failed.

# Details

The step failed with HTTP 400.[^1] GitHub saw two headers.[^2] Both values printed.[^3][^1] Backticks survive.[^4] Other tools show their input.[^5]

<sub>footer</sub>

[^1]: Call 1: `gh run view 1 --log-failed | tail -2`

    ```text
    fatal: error: 400
    ```

[^2]: Call 1: `gh run view 1 --log-failed | tail -2`

    ```text
    remote: Duplicate header: "Authorization"
    fatal: error: 400
    ```

[^3]: Call 2:

    ```bash
    for f in a b; do
      echo "$f"
    done
    ```

    ```text
    a
    b
    ```

[^4]: Call 3: ```` echo '```' `date` ````

    ````text
    ``` Thu
    ````

[^5]: Call 4: `other {"path":"x.txt"}`

    ```text
    hello
    ```
