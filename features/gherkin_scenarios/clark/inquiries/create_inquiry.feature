@javascript
@smoke
Feature: Create an inquiry
  As a user
  I want to be able to create a new inquiry

  @requires_mandate
  Scenario Outline: user creates an inquiry
    Given user logs in with the credentials and closes "start demand check" modal

    # Pre targeting (May need to change naming in our domain)
    When user clicks on "plus" button
    And  user sees dropdown menu with add contracts options
    And  user clicks on "Vertrag läuft auf mich" button
    Then user is on the targeting selection page

    # Category targeting
    When user enters "<category_search_term>" into search input field
    And  user selects "<category>" targeting option
    Then user is on the company selection page
    And  user is on the "<category>" category company targeting path

    # Company targeting
    When user enters "<company>" into search input field
    And  user selects "<company>" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "<category>" category and "<company>" company

    # Complete targeting
    When user clicks on "Weiter" button
    Then user is on the manager page
    And  user sees contract card "<category> - <company>"

    # Assert sections present
    When user clicks on contract card "<category>"
    Then user is on the manager inquiry details page
    And  user sees text "Automatischer Abholservice"
    And  user sees allgemeine informationen section
    And  user sees expertentipps zur versicherung section

    Examples:
      | company              | category           | category_search_term |
      | Allianz Versicherung | Unfallversicherung | Unfall               |

  @requires_mandate
  Scenario Outline: user uploads a document to the inquiry
    Given user logs in with the credentials and closes "start demand check" modal

    # Open contract
    When user clicks on contract card "<category>"
    Then user is on the manager inquiry details page

    # Upload document
    When user clicks on "Dokumente hochladen" link
    Then user sees "Hinweise für einen erfolgreichen Dokument-Upload" modal

    When user uploads inquiry document
    And  user closes "Hinweise für einen erfolgreichen Dokument-Upload" modal
    Then user sees 1 uploaded document card

    Examples:
      | category                 |
      | Rechtsschutzversicherung |

  @requires_mandate
  Scenario Outline: user cancels the inquiry
    Given user logs in with the credentials and closes "start demand check" modal

    # Open contract
    When user clicks on contract card "<category>"
    Then user is on the manager inquiry details page

    # Cancel inquiry
    When user clicks on "Vertrag entfernen" link
    And  user clicks on "Ja, Vertrag entfernen" button
    Then user is on the manager page
    But  user doesn't see contract card "<category> - <company>"

    Examples:
      | company              | category                 |
      | Allianz Versicherung | Rechtsschutzversicherung |

  @requires_mandate
  @desktop_only
  Scenario Outline: user adds inquiry from optimisation details page
    Given user logs in with the credentials and closes "start demand check" modal

    # Creat inquiry for Category
    When user completes the demand check
    And  user closes "first recommendation" modal
    And user clicks on "Mehr anzeigen" button

    # number inside the ring on the top
    Then user sees "1 / 7" in recommendation rings for "things" section
    And  user sees "0 / 6" in recommendation rings for "health" section
    And  user sees "0 / 2" in recommendation rings for "retirement" section

    When user clicks on recommendation card "<category>"
    Then user is on the single recommendation page
    And  user sees "<category>" category title label
    And  user sees category importance tag label

    When user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page
    And  user is on the "<category>" category company targeting path

    # Company targeting
    When user enters "<company>" into search input field
    And  user selects "<company>" targeting option
    Then user is on the recommendations page
    And  user sees "2 / 7" in recommendation rings for "things" section
    But  user doesn't see recommendation card "<category>"

    # Assert category present on manager page
    When user clicks on "Verträge" link
    Then user is on the manager page
    And  user sees contract card "<category> - <company>"

    When user clicks on contract card "<category>"
    Then user is on the manager inquiry details page

    Examples:
      | company              | category          |
      | Allianz Versicherung | Privathaftpflicht |

  @requires_mandate
  Scenario: user creates a shared contract inquiry
    Given user logs in with the credentials and closes "start demand check" modal

    # Pre targeting (May need to change naming in our domain)
    When user clicks on "plus" button
    And  user sees dropdown menu with add contracts options
    And  user clicks on "Vertrag läuft auf jemanden anderen" button
    Then user is on the third party contracts page
    And  user sees text "Versicherungsschutz über Dritte"
    And  user sees text "Du bist bei anderen Personen mitversichert? Dann füge hier Verträge hinzu, die andere abgeschlossen haben und dir Versicherungsschutz bieten."
    And  user sees text "Bitte beachte, dass wir nicht prüfen können, ob du wirklich versichert bist. Wenn du einen Vertrag hinzufügst, wird diese Versicherungsart als versichert angezeigt."

    When user clicks on "Weiter" link
    Then user is on the third party contract selection page

    When user clicks on popular option card "Privathaftpflicht"
    Then user is on the third party company selection page

    When user clicks on popular option card "Allianz Versicherung"
    Then user is on the manager page
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"

    # Navigate the contract details page and check content of the page
    When user clicks on contract card "Privathaftpflicht - Allianz Versicherung"
    Then user is on the clark 2 contract details page
    And  user sees third party contract coverage section

    When user clicks on "Mehr erfahren" button
    Then user sees text "Wir fordern für diesen Vertrag keine Informationen vom Versicherer an. Bitte teile uns deshalb mit, wenn sich etwas am Vertrag ändert und lade ggf. ein neues Dokument hoch."
