@javascript
@smoke
Feature: Document upload through messenger
  As a user
  I want to be able to login and upload a document through messenger

  @requires_mandate
  Scenario: user opens the messenger and uploads a document
    Given user logs in with the credentials and closes "start demand check" modal

    # Open messenger
    When user clicks messenger icon
    Then user sees messenger window opened

    # Upload document in messenger
    When user uploads customer document "retirement_cockpit.pdf"
    Then user doesn't see text "Fehler"
    And  user sees uploaded document in the feed
      | document_title         |
      | retirement_cockpit.pdf |

    # Login to OPS UI and open Mandate details page
    Given skip below steps in mobile browser

    When admin is logged in ops ui
    And  admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    # Assert uploaded document
    When admin clicks on "Interaktionen" section eye button
    Then admin can see that the latest uploaded file is "retirement_cockpit.pdf"

    # Forward document
    When admin clicks on forward button on latest uploaded document
    And  admin selects "Anfragedokument" option in type dropdown
    And  admin clicks on "Weiterleiten" button
    And  admin clicks the inquiry
    And  admin clicks on "Dokument" section eye button
    Then admin can see the document "retirement_cockpit.pdf" in inquiry details page
