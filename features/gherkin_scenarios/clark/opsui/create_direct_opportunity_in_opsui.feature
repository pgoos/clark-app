@javascript
@desktop_only
Feature: Create direct opportunity in OPS UI
  As an admin
  I want to be able to create a direct opportunity (with a subsequent offer) in OPS UI

  @stagings_only
  Scenario: Create a direct opportunity with a subsequent offer in OPS UI
    Given user is as the following
      | first_name | last_name          |
      | Clark      | Opportunity Tester |

    # log into OPS UI and navigate to the opportunities page
    Given admin is logged in ops ui
    When admin clicks on "Gelegenheiten" link
    Then admin is on the opportunities page

    # navigate to new opportunity with prospect page
    When admin clicks on "Neuen Interessent + Gelegenheit anlegen" link
    Then admin is on the new opportunity with prospect page

    # crate new opportunity
    When admin fills out "New opportunity with prospect" form with a customer data
    And admin selects "KFZ-Versicherung" as an opportunity category
    And admin clicks on "Anlegen" button
    Then admin is on the opportunity details page
    And admin sees text "Verkaufsgelegenheit angelegt"
    And admin sees opportunity status as "Kontaktphase"

    # edit and verify the category in drop down
    When admin clicks on "bearbeiten" link
    Then admin is on the edit opportunity page
    And admin sees the category "KFZ-Versicherung" selected in drop down

    When admin selects "Privathaftpflicht" as an opportunity category
    And admin clicks on "aktualisieren" button
    Then admin is on the opportunity details page
    Then admin sees text "Gelegenheit wurde erfolgreich aktualisiert."

    When admin clicks on "bearbeiten" link
    Then admin sees the category "Privathaftpflicht" selected in drop down

    When admin clicks on "abbrechen" link
    Then admin is on the opportunity details page
    But admin doesn't see text "Gelegenheit wurde erfolgreich aktualisiert."

    # Open new offer page
    When admin clicks on "Neues Angebot" link
    Then admin is on the create new offer page

    # create new offer
    When admin fills out new offer form with the following values
      | offer option number | Verkaufsargument   | Gruppe        | Prämie | Zahlungsrythmus | Vertragsbeginn | Vertragsende |
      | 0                   | Top-Leistung       | Adcuri        | 10     | monatlich       | 11.10.2019     | 11.10.2020   |
      | 1                   | Top-Preis-Leistung | Debeka        | 3      | vierteljährlich | 15.10.2019     | 15.10.2020   |
      | 2                   | Sparangebot        | Neue Berliner | 2      | halbjährig      | 21.10.2019     | 21.10.2020   |

    And admin marks 1 offer option as a recommended
    And admin adds following coverages to the offer comparison view
      | Sachschäden                  |
      | Vermögensschäden             |
      | Personenschäden              |
      | Selbstbeteiligung je Schaden |
      | Forderungsausfalldeckung     |

    And admin enters "Here is your offer" message for a customer
    And admin clicks on "Anlegen" button
    Then admin is on the opportunity offer page
    And admin sees text "Angebot wurde erfolgreich erstellt."

    # TODO: add more assertions here [documents, email, offer view for a customer]
