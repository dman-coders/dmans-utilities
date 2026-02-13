# Project Checker Architecture

This is a Gherkin-based audit framework for checking Platform.sh/Upsun projects across multiple dimensions: configuration, performance, security, and operational requirements.

## Core Concept

**Atomic checks** + **Feature scenarios** = **Flexible audits**

- **Atomic checks**: A growing pool of small, reusable test scripts in `checks/`
- **Feature scenarios**: Different `.feature` files that combine checks in different ways
- **Shared checks**: Common checks (project validity, domain setup) are reused across multiple audits

## Directory Structure

```
bin/project_checker/
├── run                          # Entry point: ./run PROJECT_ID
├── check                        # Wrapper that executes individual checks
├── check_bulk                   # Utility: run a check across multiple projects
├── gherkin_runner.py           # Discovers checks and executes .feature scenarios
├── audit_for_highsla.feature   # Scenario: HighSLA eligibility audit
├── audit_cache_behaviour.feature    # Scenario: Cache configuration (future)
├── audit_drupal_configuration.feature  # Scenario: Drupal-specific (future)
├── checks/                      # Pool of atomic check scripts
│   ├── check_project_id
│   ├── check_domain_is_set
│   ├── check_cache_header_is_active
│   └── ... (add more as needed)
└── audit_results.db            # SQLite database of audit results
```

## How It Works

### 1. Atomic Checks

Each check in `checks/` is a small, standalone shell script that:
- Implements a single `check()` function
- Returns exit codes: `0=pass`, `1=fail`, other codes for specific conditions
- Outputs data to STDOUT, diagnostics to STDERR

The checks define them selves for discovery by convention:
- Declares gherkin-like metadata: `CHECK_ID`, `CHECK_WHEN`, `CHECK_DESCRIPTION`
- Specifies required environment variables that act as named input parameters: `REQUIRED_PARAMETERS`
- Optionally declares additional environment variables that may be discovered and set during the check.

**Example check header:**
```bash
#!/usr/bin/env bash

CHECK_ID="check_project_tier_is_correct"
CHECK_WHEN="the project subscription should be {PROJECT_TIER} tier"
CHECK_DESCRIPTION="Verify project has the given subscription tier"

REQUIRED_PARAMETERS=( PLATFORM_PROJECT PLATFORM_CLI PROJECT_TIER )

check() {
    support_tier=$($PLATFORM_CLI -y subscription:info --project=$PLATFORM_PROJECT support_tier)
    echo "$support_tier"

    if [[ "${support_tier,,}" == "${PROJECT_TIER,,}" ]]; then
        exit 0
    else
        exit 1
    fi
}
```

### 2. Feature Scenarios

Feature files define **what** to check and **in what order**. Multiple scenarios can reuse the same checks.

**Example: audit_for_highsla.feature**
```gherkin
Scenario: Verify project basics
  When the project ID is valid for the provider
  And the organization is valid
  And the project subscription should be Enterprise tier
  Then log that The project seems healthy
```

**Future: audit_cache_behaviour.feature**
```gherkin
Scenario: Validate cache configuration
  When the project ID is valid for the provider
  And the domain is set
  And check the cache-header is active
  And the cache TTL is greater than 300 seconds
```

**Note:** Both scenarios reuse `check_project_id` and `check_domain_is_set`

### 3. The Gherkin Runner

`gherkin_runner.py`:
1. Discovers all `checks/check_*` files and indexes their `CHECK_WHEN` patterns
2. Parses the `.feature` file
3. Matches scenario steps to check patterns using regex
4. Extracts parameters from step text (e.g., `{PROJECT_TIER}` → `Enterprise`)
5. Executes checks via the `./check` wrapper
6. Maintains scenario environment (nominated variables persist between steps)
7. Reports results to SQLite database

### 4. The Check Wrapper

`./check` handles:
- Sourcing utility libraries (`feedback_functions.lib`, `audit_reporting.lib`)
- Loading the check script
- Validating required parameters
- Capturing STDOUT, STDERR, and exit codes
- Logging results to the database

## Usage

### Run a full audit
```bash
./run PROJECT_ID
```

### Run a specific scenario
```bash
python3 gherkin_runner.py audit_for_highsla.feature --name "project basics"
```

### Run a single check manually
```bash
export PLATFORM_PROJECT='abc123'
export PLATFORM_CLI='upsun'
./check check_project_id
```

### Run a check across multiple projects
```bash
./check_bulk check_domain_is_set PROJECT_ID1 PROJECT_ID2 PROJECT_ID3
```

## Parameterized Checks

This syntax is based on Gherkin.
Checks can extract values from scenario steps using `{PLACEHOLDER}` syntax:

**Check pattern:**
```bash
CHECK_WHEN="the project subscription should be {PROJECT_TIER} tier"
```

**Scenario step:**
```gherkin
When the project subscription should be Enterprise tier
```

**Result:** The runner extracts `PROJECT_TIER=Enterprise` and sets it in the check's environment.

## Return Values and Variable Persistence

Checks can return values that persist throughout a scenario.
If a check discovers a value that may be useful later, that variable is set and can be used as input for a later action.

```bash
CHECK_RETURN_VARNAME="PROJECT_ORGANIZATION_ID"

check() {
    org_id=$($PLATFORM_CLI project:info --project=$PLATFORM_PROJECT organization)
    echo "$org_id"  # This becomes $PROJECT_ORGANIZATION_ID for future checks
    exit 0
}
```

Subsequent checks can require this variable:
```bash
REQUIRED_PARAMETERS=( PROJECT_ORGANIZATION_ID )
```

EG:

```gherkin
When the project has a default domain defined 
     # (remembers the $DOMAIN as a side effect)
Then the domain URL responds to an HTTPS request
```

## Adding New Checks

1. Create `checks/check_descriptive_name`
2. Define metadata: `CHECK_ID`, `CHECK_GROUP`, CHECK_WHEN`, `CHECK_DESCRIPTION`
3. Declare `REQUIRED_PARAMETERS`
4. Implement `check()` function
5. The runner will auto-discover it

### CHECK_GROUP
 
* `project` for accounts, project properties like size, name, org. Primarily retrieved through the CLI or API
* `web` for info from http header requests, also routing, DNS and TLS topics. Retrieved using `curl` or `nslookup`, `dig` etc.
* `cache` for cache behaviour, headers, Fastly and CDN settings. Possibly retrieved from `fastly` CLI
* `internal` used for checker actions, including logging messages. Local.
* `container` about the running project instance, may include access log, or process performance lists. Mostly retrieved from ssh probes.
* `drupal` for CMS specific settings and topics. Mostly retrieved from `drush config:get` or `drush status`
* `HighSLA` for monitoring checks.

## Adding New Audits

1. Create new `.feature` file (e.g., `audit_drupal_configuration.feature`)
2. Write scenarios using existing checks
3. Add new atomic checks to `checks/` as needed
4. Update `run` script if you want a dedicated entry point

## Design Principles

- **Atomic**: Each check does one thing
- **Reusable**: Checks are shared across different audits
- **Verifiable**: Each check shows the actual CLI command used, 
  so each reported issue can be independently replicated and verified.
- **Self-documenting**: Check patterns match natural language
- **Extensible**: Add new checks without modifying framework

## Implementation Notes

### CLI Interaction
Always set `PLATFORMSH_CLI_NO_INTERACTION=1` to prevent interactive prompts. The `upsun` CLI doesn't always honor `--no-interaction` and may stall awaiting input.

### Exit Codes
- `0` = Pass
- `1` = Fail
- `21` = Warning (check failed but not critical)
- Other codes = Specific error conditions (document in check)

### Libraries Used
- `../feedback_functions.lib` - Colored logging, parameter validation
- `../audit_reporting.lib` - SQLite result tracking, status reporting
