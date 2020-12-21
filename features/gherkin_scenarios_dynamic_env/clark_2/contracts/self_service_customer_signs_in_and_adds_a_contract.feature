@javascript
Feature: Self-service customer signs in and adds a contract
  As a self-service customer
  I want to add a new contract, attach a document to this contract, see progress state and estimated response time

  @smoke
  Scenario: Self-service customer signs in and adds a contract
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    And user is a self service customer with a contract
    And user logs in with the credentials
    And user closes "new demand check" modal

    # Initiate 'add new contract' process
    When user clicks on "plus" button
    And  user sees dropdown menu with add contracts options
    And  user clicks on "Vertrag läuft auf mich" button
    Then user is on the clark 2 select category page
    And  user sees search input field

    # Select category
    When user enters "Boot" into search input field
    And  user selects "Bootshaftpflicht" search result option
    Then user is on the clark 2 select company page
    And  user sees search input field

    # Select company
    When user enters "Ass" into search input field
    And  user selects "Assurant Deutschland GmbH" search result option
    Then user is on the clark 2 select category page
    And  user sees contract card "Bootshaftpflicht - Assurant Deutschland GmbH"

    # Finish 'add new contract' process
    When user clicks on "Auswahl bestätigen" button
    Then user is on the clark 2 rewards page
    And  user sees text "Geschafft!"

    When user clicks on "Zu deinen Verträgen" link
    Then user is on the manager page
    And  user sees contract card "Bootshaftpflicht - Assurant Deutschland GmbH"

    # Navigate the contract details page and check content of the page
    When user clicks on contract card "Bootshaftpflicht - Assurant Deutschland GmbH"
    Then user is on the clark 2 contract details page
    And  user sees text "Bitte Vertrag hochladen"
    And  user sees "Bootshaftpflicht" contract details title label
    And  user sees "Assurant Deutschland GmbH" contract details secondary title label
    And  user sees text "Um deinen Vertrag zu digitalisieren und einschätzen zu können"
    And  user sees clark rating section
    And  user sees "2 item" tips and info section

    # Upload document and check results
    When user uploads contract document
    Then user sees "Geschafft!" modal

    When user clicks on "Schließen" button
    Then user sees waiting period label
    And  user sees 1 document card
    And  user sees that 1st stage of progress bar is in finished state and has "Dokument hochgeladen" title
    And  user sees that 2nd stage of progress bar is in current state and has "Dokument wird digitalisiert" title
    And  user sees that 3rd stage of progress bar is in todo state and has "Vertragsdetails verfügbar" title
    And  user sees that 4th stage of progress bar is in todo state and has "Expertenmeinung verfügbar" title
    But  user doesn't see text "Um deinen Vertrag zu digitalisieren und einschätzen zu können"
