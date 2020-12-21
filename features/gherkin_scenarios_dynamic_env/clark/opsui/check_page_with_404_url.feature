@javascript
@desktop_only
Feature: Check a page having 404 in url opsui
  As a admin
  I want to be able to check that a page having 404 in url loads in opsui

  @stagings_only
  Scenario: Check page loads successfully with 404 in url
    Given admin is logged in ops ui

    # navigate to url and verify page
    When admin navigates to 404 url page
    Then admin sees table with populated data present on page
    And admin sees "Gesellschaften" page section
    And admin sees Kommentare input field
