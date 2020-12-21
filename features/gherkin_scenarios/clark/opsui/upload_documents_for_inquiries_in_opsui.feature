@javascript
@desktop_only
Feature: Upload documents for inquiries in opsui
  As a admin
  I want to be able to upload documents to inquiries

  Scenario: Upload documents for inquiries in opsui
    # create a mandate with an inquiry
    Given user is as the following
      | first_name | last_name      |
      | Clark      | Inquiry Tester |

    When user completes the mandate funnel with an inquiry
      | category                 | company |
      | Rechtsschutzversicherung | Asstel  |

    # login to ops ui and navigate to inquiries page
    Given admin is logged in ops ui
    When admin clicks on "Anfragen" link
    Then admin is on the inquiries page

    # Open inquiry details page
    When admin clicks on the test inquiry id in a table
    Then admin is on the inquiry details page
    And admin remembers the number of existing documents

    # Prepare doc for uploading
    When admin clicks on "Dokument hinzufügen" link
    Then admin selects "Antrag" as uploaded document type
    And admin attaches file for uploading

    # Click upload and assert results
    When admin clicks on "Anlegen" button
    Then admin sees message "Dokument wurde erfolgreich erstellt."
    And admin sees that the number of documents increased by 1
