#!/usr/bin/env python3
"""
Gherkin-like runner that discovers check scripts and matches them to .feature file steps.
Each check script declares its own CHECK_WHEN and CHECK_THEN patterns.

Invoke with:
    export LOGLEVEL=6
    python3 gherkin_runner.py audit.feature
"""

import os
import re
import subprocess
import sys
import glob
import logging
import argparse
from pathlib import Path

# Configure logging to match feedback_functions.lib style
class ColoredFormatter(logging.Formatter):
    """Custom formatter with colors matching feedback_functions.lib"""
    
    COLORS = {
        'TRACE': '\033[90m',      # COLOR_GRAY (dark gray)
        'DEBUG': '\033[34m',      # COLOR_NAVY (navy blue)
        'INFO': '\033[1;32m',     # COLOR_GREEN
        'NOTICE': '\033[94m',     # COLOR_BLUE (bright blue)
        'WARNING': '\033[1;33m',  # COLOR_YELLOW
        'ERROR': '\033[1;31m',    # COLOR_RED
        'SUCCESS': '\033[92m',    # COLOR_BRIGHT_GREEN
        'RESET': '\033[0m'
    }
    
    def format(self, record):
        color = self.COLORS.get(record.levelname, self.COLORS['RESET'])
        reset = self.COLORS['RESET']
        record.msg = f"{color}{record.msg}{reset}"
        return super().format(record)

# Set up logger with custom levels
LOGLEVELS = {
  5: 'TRACE',
  10: 'DEBUG',
  20: 'INFO',
  25: 'NOTICE',
  30: 'WARNING',
  40: 'ERROR',
  45: 'SUCCESS',
}
for level_int, level_name in LOGLEVELS.items():
    logging.addLevelName(level_int, level_name)
logger = logging.getLogger('gherkin_runner')

loglevel_env = int(os.environ.get('LOGLEVEL', 7))
# The loglevel from the env is 8-1, not 0-50
# in the env, a higher number meant, with log level 1 the quietest, 8 the noisiest.
LOGLEVELS_MAPPING = {
    1: 45,  # SUCCESS
    2: 50,  # CRITICAL
    3: 40,  # ERROR
    4: 30,  # WARNING
    5: 25,  # NOTICE
    6: 20,  # INFO
    7: 10,  # DEBUG
    8: 5,   # TRACE
}
scaled_log_level = LOGLEVELS_MAPPING.get(loglevel_env)
logger.setLevel(LOGLEVELS.get(scaled_log_level, logging.INFO))
logger.log(50, f"env log level was {loglevel_env} so mapped that to py logger:{scaled_log_level} ({logging.getLevelName(scaled_log_level)})")

handler = logging.StreamHandler(sys.stderr)
handler.setFormatter(ColoredFormatter('%(message)s'))
logger.addHandler(handler)

def log(msg): logger.log(50, " -  " + msg)
def log_success(msg): logger.log(25, " ✅  " + msg)
def log_error(msg): logger.error(" ❌  " + msg)
def log_notice(msg): logger.log( 22, " 🔵 " + msg)
def log_info(msg): logger.info(" ℹ️  " + msg)
def log_warning(msg): logger.warning(" ⚠️  " + msg)
def log_debug(msg): logger.debug(" 🔍 " + msg)
def log_trace(msg): logger.log(8, " 🔍 " + msg)

class GherkinRunner:
    def __init__(self, check_dir="."):
        self.check_dir = Path(check_dir)
        self.check_registry = {}
        self.scenario_env = os.environ.copy()  # Environment that persists within a scenario
        self.discover_checks()

    def discover_checks(self):
        """Scan all check_* files and extract their CHECK_WHEN/CHECK_THEN patterns."""
        check_files = glob.glob(str(self.check_dir / "checks" / "check_*"))
        
        for check_file in check_files:
            try:
                check_info = self.extract_check_info(check_file)
                if check_info:
                    self.check_registry[check_info['id']] = check_info
                    log_trace(f"Registered check: {check_info['id']} -> {', '.join(check_info['when'])}")
                    if check_info['placeholders']:
                        log_trace(f"  Placeholders: {', '.join(check_info['placeholders'])}")

            except Exception as e:
                log_warning(f"Could not parse {check_file}: {e}")
    
    def extract_check_info(self, check_file):
        """Extract CHECK_ID, CHECK_WHEN, CHECK_THEN from a check script."""
        with open(check_file, 'r') as f:
            content = f.read()
        
        # Extract CHECK_* variables using regex
        check_id = self.extract_var(content, 'CHECK_ID')
        check_when_raw = self.extract_var(content, 'CHECK_WHEN')
        check_then = self.extract_var(content, 'CHECK_THEN')
        check_description = self.extract_var(content, 'CHECK_DESCRIPTION')
        check_return_varname = self.extract_var(content, 'CHECK_RETURN_VARNAME')

        if not check_when_raw:
            return None

        # Handle both string and array formats for CHECK_WHEN
        check_when_array = self.parse_when_patterns(check_when_raw)
        
        # Collect all placeholders from all when patterns
        check_placeholders = []
        for when_pattern in check_when_array:
            check_placeholders.extend(re.findall(r'\{([^}]+)\}', when_pattern))
        # Remove duplicates while preserving order
        check_placeholders = list(dict.fromkeys(check_placeholders))

        return {
            'id': check_id or os.path.basename(check_file),
            'when': check_when_array,  # Now always an array
            'then': check_then,
            'description': check_description,
            'placeholders': check_placeholders,
            'return_varname': check_return_varname,
            'script': check_file
        }
    
    def parse_when_patterns(self, when_raw):
        """Parse CHECK_WHEN value into array, handling both string and array formats."""
        when_raw = when_raw.strip()
        
        # Check if it's an array format (starts with parentheses or brackets)
        if when_raw.startswith('(') or when_raw.startswith('['):
            # Extract array elements - handle both bash array () and JSON-like []
            # Remove outer brackets/parentheses
            inner = when_raw[1:-1].strip()
            
            # Split by quotes and clean up
            patterns = []
            # Handle quoted strings in array
            for match in re.finditer(r'["\']([^"\'\n]*)["\']', inner):
                patterns.append(match.group(1))
            
            return patterns if patterns else [when_raw]
        else:
            # Single string
            return [when_raw]
    
    def extract_var(self, content, var_name):
        """Extract bash variable value from script content."""
        # Handle both quoted and unquoted variable assignments, including arrays
        patterns = [
            rf'{var_name}=\([^)]*\)',        # Bash array format: VAR=("item1" "item2")
            rf'{var_name}=\[[^\]]*\]',        # JSON-like array format: VAR=["item1", "item2"]
            rf'{var_name}=[\'"](.*?)[\'"]',  # Quoted values
            rf'{var_name}=([^\s\n]+)'       # Unquoted values
        ]
        
        for pattern in patterns:
            match = re.search(pattern, content)
            if match:
                # For array patterns, return the full match including brackets
                if '\\(' in pattern or '\\[' in pattern:
                    return match.group(0).split('=', 1)[1]  # Return everything after =
                else:
                    return match.group(1)
        return None
    
    def run_feature(self, feature_file, target_scenario=None):
        """Parse and execute a .feature file, optionally running only a specific scenario."""
        with open(feature_file, 'r') as f:
            lines = f.readlines()
        
        current_scenario = None
        results = []
        skip_scenario = False
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            
            if line.startswith('Scenario:'):
                current_scenario = line[9:].strip()
                
                # If target_scenario is specified, only run that scenario
                if target_scenario:
                    if target_scenario.lower() in current_scenario.lower():
                        skip_scenario = False
                        log_notice(f"\n=== {current_scenario} === (SELECTED)")
                    else:
                        skip_scenario = True
                        log_debug(f"Skipping scenario: {current_scenario}")
                        continue
                else:
                    skip_scenario = False
                    log_notice(f"\n=== {current_scenario} ===")
                
                # Reset scenario environment for new scenario with OS environment base
                self.scenario_env = os.environ.copy()
                self.scenario_env['PLATFORMSH_CLI_NO_INTERACTION'] = '1'
                continue
            
            # Skip steps if we're not running this scenario
            if skip_scenario:
                continue
                
            # Look for Given/When/Then/And steps
            if any(line.startswith(keyword) for keyword in ['Given ', 'When ', 'Then ', 'And ']):
                result = self.execute_step(line, line_num)
                results.append(result)
                
                # Handle exit conditions for Given (prerequisites)
                if line.startswith('Given ') and result['exit_code'] != 0:
                    log_error(f"Given prerequisite failed - skipping remaining scenarios: {line}")
                    break
                    
                # Handle exit conditions for other steps
                if result['exit_code'] != 0 and 'exit' in line.lower():
                    log_error(f"Exiting due to step failure: {line}")
                    break
        
        return results
    
    def execute_step(self, step_text, line_num):
        """Match step text to a check and execute it."""
        log_notice(f"")
        log_notice(f"Line {line_num}: {step_text}")

        # Find matching check
        matching_check = None
        matching_when_pattern = None
        for check_id, check_info in self.check_registry.items():
            for when_pattern in check_info['when']:

                if self.step_matches(step_text, when_pattern):
                    matching_check = check_info
                    matching_when_pattern = when_pattern
                    break
            if matching_check:
                break
        
        if not matching_check:
            log_error(f"No matching check found for: {step_text}")
            return {'step': step_text, 'exit_code': 1, 'output': 'No matching check'}
        
        # Execute the check
        try:
            log_info(f"{matching_check['description']}")
            # Extract and pass parameters from the step to the persistent scenario environment
            parameters = self.extract_parameters(step_text, matching_when_pattern)
            for param_name, param_value in parameters.items():
                log_trace(f"Extracted placeholder from pattern, and setting {param_name}={param_value}")
                self.scenario_env[param_name] = param_value

            log_debug(f"Executing: ./check {matching_check['id']}")
            result = subprocess.run(
              ['./check', matching_check['id']],
              capture_output=True,
              text=True,
              cwd=self.check_dir,
              env=self.scenario_env
            )
            return_value = result.stdout.rstrip()

            # The STDERR logging contains a lot more context,
            # dump that if we are logging heavily.
            if result.stderr.strip() and logger.level <= logging.INFO:
                # log_info(f"{logger.level} <= {logging.INFO} so extra logging")
                for line in result.stderr.rstrip('\n').split('\n'):
                    log_info(f" -- {line}")

            if result.stdout.strip():
                for line in return_value.rstrip('\n').split('\n'):
                    log_debug(line)

            if result.returncode == 0:
                log_success(f"PASS")

            else:
                log_error(f"FAIL (exit code: {result.returncode})")
                # Only dump the log on fail.
                if result.stderr:
                    logger.warning("  Check output:")
                    logger.warning("  " + "─" * 40)
                    for line in result.stderr.strip().split('\n'):
                        logger.warning(f"  │ {line}")
                    logger.warning("  " + "─" * 40)
            # Whether it succeeded or not (warning may still produce a result)
            # Save return value to persistent scenario environment
            if matching_check['return_varname']:
               self.scenario_env[matching_check['return_varname']] = return_value
               log_notice(f"Remembering that: {matching_check['return_varname']}='{return_value}'")

            return {
                'step': step_text,
                'check_id': matching_check['id'],
                'exit_code': result.returncode,
                'stdout': result.stdout,
                'stderr': result.stderr
            }
            
        except Exception as e:
            log_error(f"ERROR: {e}")
            return {'step': step_text, 'exit_code': 1, 'output': str(e)}
    
    def step_matches(self, step_text, when_pattern):
        """Check if step text matches the check's WHEN pattern."""
        # Normalize both strings for comparison
        step_normalized = step_text.lower()
        when_normalized = when_pattern.lower()
        
        # Remove common prefixes
        for prefix in ['when ', 'then ', 'and ', 'given ']:
            step_normalized = step_normalized.replace(prefix, '', 1)
        
        # Handle parameterized patterns with {param_name}
        if '{' in when_normalized and '}' in when_normalized:
            # Convert any Gherkin parameter pattern to regex
            # Input: "a parameter named {VARIABLE_NAME} is defined"
            # Output: "a parameter named (\w+) is defined"
            regex_pattern = when_normalized
            for match in re.findall(r'\{[^}]+\}', when_normalized, re.IGNORECASE):
                regex_pattern = regex_pattern.replace(match, '([\\w\\s]+)')
            return bool(re.search(regex_pattern, step_normalized))
        
        # Check if the when pattern appears in the step
        return when_normalized in step_normalized or step_normalized in when_normalized
    
    def extract_parameters(self, step_text, when_pattern):
        """Extract parameter values from step text based on pattern."""
        step_normalized = step_text
        when_normalized = when_pattern

        parameters = {}
        if '{' in when_normalized and '}' in when_normalized:
            # Find all placeholders in the pattern
            placeholders = re.findall(r'\{([^}]+)\}', when_normalized, re.IGNORECASE)
            # Convert pattern to regex with capture groups
            regex_pattern = when_normalized
            for placeholder in placeholders:
                regex_pattern = regex_pattern.replace(f'{{{placeholder}}}', r'([\w\s]+)')
            
            # Extract values from step
            match = re.search(regex_pattern, step_normalized)

            if match:
                for i, placeholder in enumerate(placeholders):
                    parameters[placeholder] = match.group(i + 1)
        
                log_notice(f"    Parameters: {parameters}")
        return parameters

def main():
    parser = argparse.ArgumentParser(
        description='Gherkin-like runner for Platform.sh HighSLA audit checks',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='Examples:\n'
               '  python3 gherkin_runner.py audit.feature\n'
               '  python3 gherkin_runner.py audit.feature --name "web service"\n'
               '  python3 gherkin_runner.py audit.feature --name basics'
    )
    
    parser.add_argument('feature_file', help='Path to .feature file')
    parser.add_argument('--name', '-n', 
                       help='Run only scenarios matching this name (substring match, case-insensitive)',
                       metavar='PATTERN')
    
    args = parser.parse_args()
    
    runner = GherkinRunner()
    
    if not args.name:
        log_info("=== Discovered Checks ===")
        for check_id, info in runner.check_registry.items():
            for when_pattern in info['when']:
                log_info(f"{check_id}: {when_pattern}")
        log_notice("")
    
    if args.name:
        log_notice(f"=== Running scenario matching '{args.name}' from {args.feature_file} ===")
    else:
        log_notice(f"=== Running all scenarios from {args.feature_file} ===")

    log(f"Logging level is {logger.level} ({logging.getLevelName(logger.level)})")
    if logger.level <= logging.INFO :
      log_notice(f"Additional debug logs from sub-processes will be exposed")

    results = runner.run_feature(args.feature_file, args.name)
    
    # Summary
    passed = sum(1 for r in results if r['exit_code'] == 0)
    total = len(results)
    log_notice("")
    log_notice(f"=== Summary ===")
    log_notice(f"Passed: {passed}/{total}")

if __name__ == "__main__":
    main()
