# Check projects for HighSLA status and eligibility. provide exact instructions for remediating or repairing any missing expectations.

Feature: HighSLA Eligibility and Activation

Background:
  Given a parameter named PLATFORM_PROJECT is defined
  Given a parameter named PLATFORM_CLI is defined

Scenario: Verify project basics
  When the project ID is valid for the provider
  And the organization is valid
  And the project subscription should be Enterprise tier
  Then log that The project seems healthy

Scenario: Validate web service
  When the default branch is active
  And the domain is set
  And the URL is set
  And the URL responds to an HTTPS request
  And the response headers should show it is served by Platform.sh
  Then check the the cache-header is active


Scenario: Check current HighSLA status
  Given a parameter named PLATFORM_PROJECT is defined
  Given HighSLA is not already active
  Then provide steps to enable HighSLA



