@javascript
@desktop_only
Feature: Create a new product in OPS UI
  As an admin
  I want to be able to create a new product in OPS UI

  @stagings_only
  @requires_mandate
  Scenario: Create a new product in OPS UI
    # Login and navigate to mandates page
    Given admin is logged in ops ui
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    # Open first mandate in the table
    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page
    And admin remembers the number of existing products

    # Open new product page and fill the form
    When admin clicks on "Anfrage" section eye button
    And admin clicks on "Produkt hinzufügen" link
    Then admin is on the new product page
    And admin selects "Privathaftpflicht" as the product category
    And admin selects "ACE" as the product group
    And admin fills product number with random value
    And admin enters "11122018" into Vertragsbeginn input field
    And admin enters "10" into Prämie input field
    And admin selects "monatlich" as the product premium period

    # Click apply and assert results
    When admin clicks on "Anlegen" button
    Then admin is on the mandate details page
    And admin sees that the number of products increased
    And admin sees the new product in the first row of products table

    When admin clicks on "Produkte" link
    And admin clicks on the test product id in a table
    Then admin is on the product_details page

# Check different sections appearing
    And admin sees product status as "Details verfügbar"
    And admin sees "Provisionen" page section
    And admin sees "Zahlungen" page section
    And admin sees text "Zah­lungs­typ"
    And admin sees "Dokumente" page section

# Check data under different sections appearing
    When admin clicks on "Dokumente" section eye button
    And admin sees text "Document type"
    And admin sees "Versicherungssummen / Leistungen" page section

    When admin clicks on "Versicherungssummen / Leistungen" section eye button
    Then admin sees text "Sachschäden"
    And admin sees text "Allmählichkeitsschäden"
    And admin sees "Interaktionen" page section
    And admin sees Kommentare input field

# Check functionality under different sections
    When admin clicks on "Zahlung hinzufügen" link
    Then admin sees text "Zahlung hinzufügen"

    When admin clicks on "Abbrechen" button
    Then admin is on the product_details page

    When admin clicks on "Dokument hinzufügen" link
    Then admin is on the create new document page
