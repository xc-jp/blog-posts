---
layout: single
title: GitHub Actions CI/CD
issue-date: 2022.05.10
author: Liu Yuxi
tags: ["GitHub Actions", "CI"] 
excerpt: Continous integration and delivery by using GitHub Actions
---

## Introduction
### What is CI/CD

Integration & Delivery

Devlopment → Test → Deployment

- CI: Continuous Integration
- CD: Continuous Delivery

**Continuous**: make above steps interwoven, rather than in batches.
For this, we need **automation**.

### GitHub Actions overview

```yaml
name: learn-github-actions
on: push
jobs:
  check-bats-version:
  runs-on: ubuntu-latest
   steps:
     - uses: actions/checkout@v3
     - uses: actions/setup-node@v3
       with:
         node-version: '14'
     - run: npm install -g bats
     - run: bats -v
```

Setup hierarchy:
- **Workflow**: a configuration file
- **Job**: a set of steps that can execute in parallel
- **Step**: an action or a script
- **Action**: a configurable and reusable script (c.f. a function)

[//]: # ![](/assets/images/overview-actions-simple.png)  there is a problem to render the image
[//]: # Figure 1: Runtime overview

### Advantages of GitHub Actions

- Cost
    - Free hosted runners for **public** repository
    - Free self-hosted runners for **private** repository
    - c.f. Buildkite: per user charge
- Integration with GitHub
    - No need for additional access to the repository
    - No need for additional access to the runner
    - No need for CI access management
        - Read access to the repository → read access to CI
        - Write access to the repository → write access to CI
    - Embedded UI

### Security policy

{% raw %}
- **DO NOT** use self-hosted runners for a public repository
    - Risk: allow arbitrary code execution on your machine.
    - Configurable requirement for PR: e.g. approval from someone with write access.
- Secrets from settings: `${{ secrets.PASSWORD }}`
    - For self-hosted runners, store on the machine instead.
{% endraw %}

## Techniques
### Expressions

{% raw %}
Use `${{ <expression> }}` to pragmatically generate configuration.
{% endraw %}

- Literals: null, true, 42, 'spam'
- Operators: matrix.device == 'cpu'
- Functions:
    - contains('Hello world', 'llo')
    - format('Hello {0} {1} {2}', 'Mona', 'the', 'Octocat')
    - toJSON(job)
- Job status: cancelled()
- Object filters: fruits.*.name

[https://docs.github.com/en/actions/learn-github-actions/expressions](https://docs.github.com/en/actions/learn-github-actions/expressions)

### Contexts

{% raw %}
Variables of workflow information, `${{ <context> }}`

Conditional execution example:

```yaml
- run: mkdir ${{ github.job }}
if: ${{ github.ref == 'refs/heads/main' }}
```
{% endraw %}

### Triggering a workflow

```yaml
on: push
on:
push:
branches:
- 'releases/**'
- '!releases/**-alpha'
```

[https://docs.github.com/en/actions/using-workflows/triggering-a-workflow](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow)

### Jobs: dependency

Jobs run in parallel and may be assigned to different runners.

{% raw %}
```yaml
jobs:
  job1:
  job2:
    needs: job1
  job3:
    if: ${{ always() }}
    needs: [job1, job2]
```
{% endraw %}

[https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

### Jobs: runner selection

Use a set of labels to select a runner.
- Hosted
    - runs-on: windows-latest
- Self-hosted
    - runs-on: [self-hosted, x86_64-linux, docker]

A runner will be selected if it has **all** of the labels.
When registering runners, set corresponding labels.

### Build matrix

Procedurally generate build configuration combinations.

{% raw %}
```yaml
runs-on: ${{ matrix.os }}
strategy:
  matrix:
    node: [8, 10, 12, 14]
    os: [macos-latest, windows-latest, ubuntu-18.04]
    include:
      - os: ubuntu-18.04
        node: 15
    exclude:
      - os: macos-latest
        node: 8
```
{% endraw %}

[https://docs.github.com/en/actions/using-jobs/using-a-build-matrix-for-your-jobs](https://docs.github.com/en/actions/using-jobs/using-a-build-matrix-for-your-jobs
)

### Timeout

```yaml
jobs:
  job1:
    timeout-minutes: 480
    steps:
      - run: nix build
      - timeout-minutes: 120
```

[https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepstimeout-minutes](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepstimeout-minutes)

### Default environment variables

```bash
$ printenv
...
RUNNER_TRACKING_ID=github_6d8c2243-acee-49c5-8c10-f774111d02bc
GITHUB_REPOSITORY_OWNER=xc-jp
GITHUB_ACTIONS=true
CI=true
...
```

[https://docs.github.com/en/enterprise-server@3.4/actions/learn-github-actions/environment-variables#default-environment-variables](https://docs.github.com/en/enterprise-server@3.4/actions/learn-github-actions/environment-variables#default-environment-variables
)

### Setup environment variables

{% raw %}
```yaml
env:
  DAY_OF_WEEK: Monday
jobs:
  greeting_job:
    runs-on: ubuntu-latest
    env:
      Greeting: Hello
    steps:
      - if: ${{ env.DAY_OF_WEEK == 'Monday' }}
        run: echo ”$Greeting $First_Name. Today is $DAY_OF_WEEK!”
        env:
          First_Name: Mona
```
{% endraw %}

[https://docs.github.com/en/actions/learn-github-actions/environment-variables](https://docs.github.com/en/actions/learn-github-actions/environment-variables)

#### Setup environment variables from the script

```yaml
- run: export HOSTNAME=$(hostname --fqdn)
- run: echo ”$HOSTNAME”
```

HOSTNAME is not available in the second run step.

```yaml
- run: echo ”HOSTNAME=$(hostname --fqdn)” >> $GITHUB_ENV
- run: echo ”$HOSTNAME”
```

HOSTNAME will be available for all steps after it.

[https://stackoverflow.com/a/57969570](https://stackoverflow.com/a/57969570)

```yaml
- run: echo ”HOSTNAME=$(hostname --fqdn)” >> $GITHUB_ENV
- run: echo ”$HOSTNAME”
```

Under the hood, appending to a temporary file:

```bash
$ echo $GITHUB_ENV
/run/github-runner/.../_temp/_runner_file_commands/
set_env_63e44268-e0e8-4bfc-839e-e8aed075a6b6
```

### Artifact and log

Definition: persistent data after the workflow run
Retention period (default: 90 days)
- Public: 1~90 days
- Private: 1~400 days

Also constrained by:
- Organization/enterprise policy
- Storage limit (may generate billing)

For hosted artifact storage:
- actions/upload-artifact[^1]
- actions/download-artifact[^2]

[^1]: [https://github.com/actions/upload-artifact](https://github.com/actions/upload-artifact)
[^2]: [https://github.com/actions/download-artifact](https://github.com/actions/download-artifact)


Our solution for hosted runners:

{% raw %}
```yaml
upload-artifacts ”Result tarballs” ${{ github.job }}
result '*.tar.gz'
```
{% endraw %}

- Each file is stored to a s3 bucket.
- A public link is added to the log.
- Links are grouped.
- Only those who has access to the log has access to the artifacts.
- The retention policy is set separately.

```bash
echo ”::group::$1”
UUID=”$(uuidgen)”
export TARGET=”$2/$UUID”
find -L ”$3” -name ”$4” -type f \
    -exec aws s3 cp {} ”s3://.../$TARGET/” --only-show-errors \; \
    -exec sh -c 'echo ”https://.../$TARGET/$(basename {})”' \;
echo ”::endgroup::”
```

## Rouch corners
### Hard to see runner status

The runner status overview is only available in configurations.
Not every developer has configuration access.

### Development process

Normally you have to ***push to GitHub** to test.
There are tools like act for local runs.
However,
- They usually requires docker.
- You need to set up secrets locally (like keys).

### Gayaml (the GitHub Actions flavor of yaml)

- No anchors and aliases (&anchor and *anchor)
- Context expansion may cause syntax errors

{% raw %}
```yaml
strategy:
  matrix:
    device: [cpu, gpu]
runs-on: [self-hosted, ${{ matrix.device }}]
```
{% endraw %}

but this works:

{% raw %}
```yaml
runs-on:
- self-hosted
- ${{ matrix.device }}
```
{% endraw %}

### Context availability

{% raw %}
```yaml
test-context:
  steps:
    - name: ${{ github.job }}
      run: ...
    - run: echo ${{ github.job }}
```
{% endraw %}

github.job: job id (i.e. test-context)

However, actually:

- First step: empty
- Second step: test-context

In some cases, it even becomes run.

>*github.job is not available until the job actually runs*.

but it’s not clear when.

[https://docs.github.com/en/actions/learn-github-actions/contexts#context-availability](https://docs.github.com/en/actions/learn-github-actions/contexts#context-availability)

### Isolation?

```yaml
- run: mkdir test-dir
```

Where is test-dir after the run? Is it cleared?

```bash
$ sudo ls -la /run/github-runner/.../ci-experiments/ci-experiments \
  | tail -n +2 | tr -s ' ' | cut -d' ' -f1,3,4,9
drwx--x--x github-runner github-runner .
drwx--x--x github-runner github-runner ..
drwx--x--x github-runner github-runner .git
drwx--x--x github-runner github-runner .github
drwx--x--x github-runner github-runner test-dir
```

Permission 711 with the github-runner user as the owner.
Overwritten upon the next run.

## Personal experience
### Workflows or jobs?

How to group jobs into workflows?
- Different trigger conditions → different workflows
- Job dependencies → same workflow
- Share same workflow environment → same workflow
Other than these, logical relations.

### General comments

- CI/CD is very useful
    - Automate testing
    - Enforce policies for collaborative projects
- Nix is a very helpful
    - “Migrate” by mere copying
    - Add ad hoc dependency: nix run nixpkgs#hello
    - Set up runner machines