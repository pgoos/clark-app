@javascript
@desktop_only
Feature: Search categories in the Product new page
  As an admin
  I want to be able to Search categories on the Product new page

  @stagings_only
  @requires_mandate
  Scenario: Search categories on the Product new page in OPS UI
    # Login and navigate to mandates page
    Given admin is logged in ops ui
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    # Open first mandate in the table
    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page
    And admin remembers the number of existing products

    # Open new product page

    When admin clicks on "Anfrage" section eye button
    And admin clicks on "Produkt hinzufügen" link
    Then admin is on the new product page

    # Search the category (keywords in alphabetical order)

    When admin selects "haftpflichtversicherung rech unfall wohn" as the product category
    Then admin sees text "Privathaftpflicht-, Wohngebäude-, Hausrat-, Rechtsschutz-, Unfall- & Tierhalter-Haftpflichtversicherung"

    # Search the category (keywords in the not alphabetical order)

    When admin selects "haftpflichtversicherung unfall wohn rech" as the product category
    Then admin sees text "Privathaftpflicht-, Wohngebäude-, Hausrat-, Rechtsschutz-, Unfall- & Tierhalter-Haftpflichtversicherung"
