@javascript
@desktop_only
Feature: As admin I suppose to see generated payments transaction after upload xls file

  @ignore
  @Flaky
  @requires_mandate
  Scenario: Payment transactions generate after upload xls file
    # Create Product
    Given admin created products

    # Open product details page
    When admin clicks on "Produkte" link
    And admin clicks on the test product id in a table
    Then admin is on the product_details page
    And admin remembers the number of existing payments

    # Upload payments file
    When admin clicks on "Upload Abrechnung" link
    Then admin is on the accounting transactions upload page

    When admin attaches XLSX file exists with payments for that new product
    And admin clicks on "Hochladen" button
    Then admin sees message "Die Datei wurde hochgeladen und wird verarbeitet."

    # Open product page again
    When admin clicks on "Produkte" link
    And admin clicks on the test product id in a table

    # assert the results
    Then admin is on the product_details page
    And admin sees that the number of payments increased
