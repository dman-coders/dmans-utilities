# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is the `project_checker` system - a Gherkin-based audit framework for checking Platform.sh/Upsun projects across multiple dimensions (health, configuration, security, performance). It provides a pool of atomic, reusable checks that can be combined in different feature scenarios.

## Key Components

**Main entry point**: `./run` - Executes Gherkin runner with specified feature file and given project ID

**Gherkin runner**: `gherkin_runner.py` - Auto-discovers check scripts, matches Gherkin steps to checks, executes via `./check` wrapper

**Core executable wrapper**: `./check` - Sources libraries, handles parameter validation, executes check functions, captures output, and reports to audit database

**Check scripts**: `check_*` files containing:
- Metadata: `CHECK_ID`, `CHECK_WHEN`, `CHECK_THEN`, `CHECK_DESCRIPTION`
- Required parameters: `REQUIRED_PARAMETERS` array
- Business logic in `check()` function only
- Documentation: `literal_check_command` showing the actual CLI command
This library is expected to be expanded and re-used.

**Test scenarios**: `*.feature` files - Gherkin format test scenarios defining what to check (e.g., `audit_for_highsla.feature`)

## Answering Questions About Projects

When the user asks questions about project status, use the appropriate check:

| Question Pattern | Check to Run | Required Environment Variables |
|-----------------|-------------|-------------------------------|
| "Does project X have HighSLA enabled?" | `check_highsla_is_active` | `PLATFORM_PROJECT`, `PLATFORM_CHECKMATE_FOLDER` |
| "Is HighSLA configured for X?" | `check_highsla_is_not_active` | `PLATFORM_PROJECT`, `PLATFORM_CHECKMATE_FOLDER` |
| "What tier is project X?" | `check_project_tier_is_correct` | `PLATFORM_PROJECT`, `PROJECT_TIER` (e.g., "Enterprise") |
| "Is project X's deployment healthy?" | `check_deployment_status` | `PLATFORM_PROJECT`, `PLATFORM_BRANCH` |
| "What domain does project X use?" | `check_domain_is_set` | `PLATFORM_PROJECT`, `PLATFORM_BRANCH` |
| "Is project X responding?" | `check_domain_responds_to_https_request` | `DOMAIN` |
| "Is X served by Platform.sh?" | `check_for_platformsh_headers` | `DOMAIN` |
| "Can I SSH to project X?" | `check_ssh_connectivity` | `PLATFORM_PROJECT`, `PLATFORM_BRANCH` |
| "What's the default branch?" | `check_project_default_branch` | `PLATFORM_PROJECT` |
| "What organization owns X?" | `check_project_organization` | `PLATFORM_PROJECT` |
| "How many apps does X have?" | `check_project_app_name` | `PLATFORM_PROJECT`, `PLATFORM_BRANCH` |

**How to answer these questions:**

Option 1 - Run check directly:
```bash
export PLATFORM_PROJECT='3x4fowkdbgsbe'
export PLATFORM_CLI='upsun'
bin/project_checker/check check_highsla_is_active
```

Option 2 - Query recent audit results:
```bash
./query_audit --project=3x4fowkdbgsbe --check=check_highsla_is_active
```

**Auto-discovering available checks:**
```bash
python3 -c "from gherkin_runner import GherkinRunner; r=GherkinRunner(); \
  for id, info in r.check_registry.items(): \
    print(f'{id}: {info[\"description\"]}')"
```

## Common Development Commands

```bash
# Set required environment variables
export PLATFORM_PROJECT='your-project-id'
export PLATFORM_CLI='upsun'
export PLATFORMSH_CLI_NO_INTERACTION=1

# Run a single check
./check check_project_tier_is_enterprise

# Run full audit suite
python3 gherkin_runner.py audit.feature

# Query audit database for recent results
./query_audit --project=PROJECT_ID --check=CHECK_ID

# Test check script discovery
python3 -c "from gherkin_runner import GherkinRunner; r=GherkinRunner(); print(r.check_registry)"
```

## Code Architecture

**Libraries**: 
- `../feedback_functions.lib` - Colored logging, parameter validation, command execution
- `../audit_reporting.lib` - Database reporting, status code handling

**Check Pattern**:
1. Each check declares its Gherkin patterns and requirements
2. `./check` wrapper sources libraries and the check script
3. Wrapper calls `check()` function and captures all output
4. Results logged to audit database via `audit_report_result`

**Environment Variables**:
- `PLATFORM_PROJECT` - Platform.sh project ID (required)
- `PLATFORM_CLI` - CLI command to use (default: 'platform')
- `PLATFORMSH_CLI_NO_INTERACTION=1` - Prevents interactive prompts

## Development Guidelines

**Code style**:
- Follow existing code style and conventions
- Use descriptive and consistent variable and function names
- Monitor for common patterns to refactor into libraries for re-use
- prefer atomic, small scripts over large monolithic apps
- Provide debug feedback verbosely, but moderated by LOGLEVEL.

**Creating new checks**:
1. Copy existing check script pattern
2. Update metadata variables (`CHECK_ID`, `CHECK_WHEN`, `CHECK_GROUP`, etc.)
3. Implement business logic in `check()` function only
4. Use `literal_check_command` to document the actual CLI command
5. **CRITICAL**: When executing `$literal_check_command`, always use `eval` for bash/zsh compatibility:
   ```bash
   # CORRECT:
   RESULT=$(eval $literal_check_command 2>/dev/null)

   # WRONG (breaks in zsh):
   RESULT=$($literal_check_command 2>/dev/null)
   ```
   This ensures variables in the command string are properly expanded in both shells.
6. Script will auto-register with Gherkin runner

**Check design principles**:
- Keep checks lightweight - wrapper handles all common tasks
- Always output the raw result to STDOUT for logging
- Use exit codes: 0=pass, 1=fail, other=specific error conditions
- Include repair instructions in error messages
- Make commands reproducible outside the audit system

**Environment context**:
- Checks can read from environment variables set by previous checks
- STDOUT from checks is captured and can be parsed by subsequent checks
- Use `REQUIRED_PARAMETERS` to declare dependencies

## Shell Compatibility (bash/zsh)

The framework is designed to work in both bash and zsh environments:

**Key compatibility requirements:**

1. **Use `eval` for `literal_check_command` execution** (see above)
2. **Declare `local` variables at function top, not in loops** - zsh echoes local declarations in interactive contexts
3. **Avoid bash-specific syntax**:
   - Use `[[ ]]` for conditionals (works in both)
   - Avoid `${!var}` indirect expansion (bash-only)
4. **Script sourcing detection**:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
   ```
   This handles both bash's `BASH_SOURCE` and zsh's `%x` expansion

**Common zsh issues to avoid:**
- Variables in command strings not expanding → Use `eval`
- `local` declarations producing output in loops → Move outside loop
- Indirect variable expansion failing → Use `eval echo \$$varname` instead of `${!varname}`

## HighSLA Enablement Refactoring Plan

**Goal**: Consolidate `bin/checkmate-enhanced` functionality into atomic checks within the project_checker framework.

**Current State:**
- `audit_for_highsla.feature` - Preflight validation (tier check, web service validation, HighSLA status)
- `bin/checkmate-enhanced` - Standalone script for URL detection, Fastly detection, YAML generation, git workflow

**Strategy**: Extract detection/action logic from `checkmate-enhanced` into reusable atomic checks.

### New Checks to Create

**Detection Checks (read-only):**
1. `check_framework_detected` - Detects application framework (Drupal, WordPress, Symfony, Rails, PHP, etc.)
   - `CHECK_WHEN="the framework is detected"`
   - `CHECK_RETURN_VARNAME="DETECTED_FRAMEWORK"`
   - Uses curl to analyze headers/content

2. `check_domain_uses_fastly` - Fastly DNS detection and service ID lookup
   - `CHECK_WHEN="the domain uses Fastly CDN"`
   - `CHECK_RETURN_VARNAME="FASTLY_SERVICE_ID"`
   - Uses logic from `bin/fastly_get_service` (Fastly API lookup)

3. `check_domain_response_is_cacheable` - Cacheability analysis
   - `CHECK_WHEN="the domain response is cacheable"`
   - `CHECK_RETURN_VARNAME="IS_CACHEABLE"`
   - Analyzes cache-control headers (no-cache, no-store, private, max-age)

4. `check_primary_url_discovered` - Primary URL from routes
   - `CHECK_WHEN="the primary URL is discovered"`
   - `CHECK_RETURN_VARNAME="PRIMARY_URL"`
   - Uses Platform CLI to get primary route (different from `check_domain_is_set` which returns DOMAIN)

5. `check_final_url_after_redirects` - Redirect following
   - `CHECK_WHEN="the final URL after redirects is determined"`
   - `REQUIRED_PARAMETERS=(PRIMARY_URL or DOMAIN)`
   - `CHECK_RETURN_VARNAME="FINAL_URL"`
   - Uses curl to follow redirects

**Action Checks (write operations):**
6. `check_highsla_yaml_generated` - YAML configuration generation
   - `CHECK_WHEN="the HighSLA YAML configuration is generated"`
   - `REQUIRED_PARAMETERS=(PLATFORM_PROJECT FINAL_URL FASTLY_SERVICE_ID DETECTED_FRAMEWORK)`
   - Generates YAML in `PLATFORM_CHECKMATE_FOLDER`

7. `check_git_branch_prepared` - Git branch creation
   - `CHECK_WHEN="the git feature branch {TICKET_ID} is prepared"`
   - Creates/switches to branch in checkmate repo

8. `check_changes_committed` - Git commit
   - `CHECK_WHEN="the changes are committed with message {COMMIT_MESSAGE}"`

### Future Feature File: enable_highsla.feature

This will combine preflight validation + detection + action into a unified workflow that replaces `checkmate-enhanced`.

## Current Implementation Progress

**Goal**: Replace `bin/checkmate-enhanced` monolithic script with atomic checks that can be composed into scenarios.

**Status**: In progress - creating detection checks first, then will add action checks.

### Completed Checks

1. ✅ **`check_url_route`** (formerly check_url_route_is_valid)
   - Discovers PRIMARY_URL from environment routes
   - Returns as `URL` for use by other checks
   - Fallback logic: primary route → first HTTPS URL

2. ✅ **`check_framework_detected`**
   - Detects application framework from HTTP headers and content
   - Returns `DETECTED_FRAMEWORK`
   - Requires `URL` input
   - Detects: Drupal 7-10, Magento 1-2, WordPress, Symfony, Rails, defaults to PHP

3. ✅ **`check_domain_uses_fastly`**
   - DNS check for Fastly IPs (151.101.x.x)
   - Queries Fastly API for service ID matching PLATFORM_PROJECT
   - Returns `FASTLY_SERVICE_ID`
   - Requires `DOMAIN` and `PLATFORM_PROJECT` inputs
   - Exit code 21 (warning) if Fastly detected but service ID not found

### Design Patterns Established

- Variable naming: Use UPPERCASE for returned values (URL, DOMAIN, PLATFORM_PROJECT)
- Don't redefine `literal_check_command` inside check() function
- Don't manually log `literal_check_command` - wrapper handles this
- Use single top-level `literal_check_command` for both documentation and execution
- Checks use `URL` not `DOMAIN` for HTTP operations (more flexible)
- Removed redundant `_is_valid` suffixes from check names

### Next Steps

**Detection checks to create:**
4. `check_domain_response_is_cacheable` - Analyze cache-control headers
5. `check_final_url_after_redirects` - Follow HTTP redirects to final URL

**Action checks to create (write operations):**
6. `check_highsla_yaml_generated` - Generate YAML config in checkmate repo
7. `check_git_branch_prepared` - Create/checkout feature branch
8. `check_changes_committed` - Git commit with message

**Then create unified scenario:**
- Create `enable_highsla.feature` that chains all checks together
- Replace `bin/checkmate-enhanced` with scenario-based workflow
- Test end-to-end automation

### Notes for After Restart

- Linear MCP integration will be available after restart
- Task: Review Linear project and count sub-issues
- Continue building remaining atomic checks
- Eventually compose full enable_highsla.feature scenario
