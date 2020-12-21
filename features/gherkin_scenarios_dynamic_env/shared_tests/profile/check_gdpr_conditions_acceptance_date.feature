@smoke
@javascript
Feature: Check GDPR conditions acceptance date
  As a user
  I want to be able to see when I had accepted GDPR conditions

  @requires_mandate
  Scenario: user checks GDPR conditions acceptance date in profiling page
    Given user logs in with the credentials and closes "start demand check" modal

    # open mandate profiling page and check GDPR conditions acceptance date
    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page
    And  user sees that the GDPR conditions acceptance string ends with current date
