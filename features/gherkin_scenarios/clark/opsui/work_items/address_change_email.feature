Feature: Address change email
  As an insurer
  I want to receive notification email about clark customer address change

  @requires_mandate
  Scenario: Customer changes address in Clark app

    Given user has the following product
      | category_name | company_name  |
      | Hausrat       | ADAC          |

    And admin accepts users mandate
    And user logs in with the credentials and closes "start demand check" modal

    # Navigate to customer settings
    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page

    # Update street name and house number attributes
    When user updates the profile information with following values
      | street-name                  | house-number |
      | Change Address Notification  | 10           |
    And  user clicks on "Speichern" button
    Then user is on the manager page

    # Navigate to working items
    When admin navigates to admin landing page
    And admin clicks on "Aufgaben" link
    Then admin is on the work items page

    # Open address change working item
    When admin clicks on "geänderte Adressen" link
    Then admin sees current user in the changed addresses table

    # Open mandate addresses page
    When admin clicks on the test address id in a table
    Then admin is on the mandate addresses page
    And admin sees in the addresses change requests table 2 records

    # Open edit address page
    When admin clicks 1th address change request
    Then admin is on the mandate address edit page

    # Submit change and notify insurers
    When admin selects accept_rules checkbox
    And admin clicks on "aktualisieren" button
    Then "user" receives an email with the subject "Deine neue Adresse wurde übermittelt"
    And "user" receives an email with the content "vielen Dank für deine Mail und"
    And "service@adac.de" receives an email with the subject "Adressänderung für VSNR"
    And "service@adac.de" receives an email with the content "teilen wir Ihnen folgende Adressänderung mit"

  @requires_mandate
  Scenario: Admin changes address in OPS UI
    Given user has the following product
      | category_name | company_name  |
      | Hausrat       | ADAC          |

    And admin accepts users mandate

    # Navigate to user's mandate
    When admin navigates to admin landing page
    And admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    # Navigate to address change page
    When admin clicks on "address change" button
    Then admin is on the mandate address edit page

    # Submit change and notify insurers
    When admin fills out "address edit" form
    |street        |house_number|
    |Changed street|15          |

    And admin selects accept_rules checkbox
    And admin clicks on "aktualisieren" button
    Then "user" receives an email with the subject "Deine neue Adresse wurde übermittelt"
    And "user" receives an email with the content "vielen Dank für deine Mail und"
    And "service@adac.de" receives an email with the subject "Adressänderung für VSNR"
    And "service@adac.de" receives an email with the content "teilen wir Ihnen folgende Adressänderung mit"
