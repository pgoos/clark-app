@javascript
@desktop_only
Feature: Check feature switcher functionality in OPS UI
  As an admin
  I want to be able to turn features on and off in OPS UI

  @stagings_only
  Scenario: Switch finance 2.0 feature in OPS UI
    Given admin is logged in ops ui

    When admin clicks on "Settings" link
    Then admin is on the admin settings page
    And admin sees table with populated data present on page

    # switch finance 2.0 feature off and verify
    When admin turns off "ACCOUNTING" feature switch
    And admin clicks on "Buchhaltung" link
    Then admin is on the accounting cost centers page
    And admin does not see "Upload Abrechnung" link on page

    When admin clicks on "Settings" link
    Then admin is on the admin settings page
    And admin sees table with populated data present on page

    # switch finance 2.0 feature on and verify
    When admin turns on "ACCOUNTING" feature switch
    And admin clicks on "Buchhaltung" link
    Then admin is on the accounting cost centers page
    And admin sees "Upload Abrechnung" link on page
