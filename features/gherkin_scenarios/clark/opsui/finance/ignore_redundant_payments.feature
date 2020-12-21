@javascript
@desktop_only
Feature: As admin I suppose to not be able to import payments if upload the same file twice

  @ignore
  @Flaky
  @requires_mandate
  Scenario: Payment transactions don't generate after upload xls file more than once
    Given admin uploaded FondsFinanz payment for a created product

    # Upload the same payments file
    When admin clicks on "Upload Abrechnung" link
    Then admin is on the accounting transactions upload page

    When admin attaches the same XLSX file again
    And admin clicks on "Hochladen" button
    Then admin sees message "Die Datei wurde hochgeladen und wird verarbeitet."

    # Open product page again
    When admin clicks on "Produkte" link
    And admin clicks on the test product id in a table

    # assert the results
    Then admin is on the product_details page
    And admin sees that the number of payments is the same
