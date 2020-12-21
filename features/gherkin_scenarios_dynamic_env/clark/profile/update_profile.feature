@smoke
@javascript
Feature: Update profile in profiling page
  As a user
  I want to be able to login and update my profile

  @requires_mandate
  Scenario: user updates the profile in profiling page
    Given user logs in with the credentials and closes "start demand check" modal

    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page

   # Update Profile Page
    When user updates the profile information with following values
      | first-name    | last-name | birth-date | street-name | house-number | post-code | city-name |
      | Clark_profile | Testing   | 21.10.1992 | Geothe Str  | 10           | 60313     | Frankfurt |

    And  user clicks on "Speichern" button
    Then user is on the manager page

    # Verifying updated profile values
    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page
    And  user sees that the profile form is filled with the following values
      | first-name    | last-name | birth-date | street-name | house-number | post-code | city-name |
      | Clark_profile | Testing   | 21.10.1992 | Geothe Str  | 10           | 60313     | Frankfurt |
