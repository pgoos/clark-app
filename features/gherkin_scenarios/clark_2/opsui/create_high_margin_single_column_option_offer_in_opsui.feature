@javascript
@desktop_only
@smoke
Feature: Create high margin single column option offer in OpsUI
  As an admin
  I want to be able to create HM single column option offers for clark2 customers

  Scenario: create high margin single column option offer
    Given user is as the following
      | first_name | last_name                     |
      | Clark 2.0  | HM Single Option Offer Tester |

    # open OPS UI, log in as an admin and navigate to opportunities page
    Given admin is logged in ops ui
    When admin clicks on "Gelegenheiten" link
    Then admin is on the opportunities page

    # navigate to new opportunity with prospect page
    When admin clicks on "Neuen Interessent + Gelegenheit anlegen" link
    Then admin is on the new opportunity with prospect page

    # create new opportunity
    When admin fills out "New opportunity with prospect" form with a customer data
    And admin selects "Berufsunfähigkeitsversicherung" as an opportunity category
    And admin clicks on "Anlegen" button
    Then admin is on the opportunity details page
    And admin sees text "Verkaufsgelegenheit angelegt"
    And admin sees opportunity status as "Kontaktphase"

    # open new single option offer creation form
    When admin clicks on "Neues Angebot mit einer Option" link
    Then admin is on the single option offer form edit page

    # fill in the form
    When admin selects "Top Leistung" option in verkaufsargument dropdown
    And admin selects "ALVSBV" option in tarif dropdown
    And admin enters "200" into pramie input field
    And admin selects "monatlich" option in zahlweise dropdown
    When admin fills out angezeigte leistungen section with following values
      | versicherungsbeginn | ablaufalter   | rating versicherungsgesellschaft |
      | 01/01/2021          | 5             | top rating                       |

    And admin fills out angezeigte dokumente section with following values
      | document type         |
      | VVG-Informationspaket |
      | Vergleichsdokument    |

    And admin clicks on "Anlegen" button

    # offer page is displayed
    Then admin is on the opportunity offer page
    And offer is in "in erstellung" status
