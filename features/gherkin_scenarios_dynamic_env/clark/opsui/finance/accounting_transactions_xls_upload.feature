@javascript
@desktop_only
Feature: Upload accounting transactions in opsui
  As a admin
  I want to be able to upload accounting transactions xlxs

  @requires_mandate
  Scenario: Upload xlsx file and display mismatched transactions

    # login to ops ui and navigate to upload accounting reports page
    Given admin is logged in ops ui
    When admin clicks on "Upload Abrechnung" link
    Then admin is on the accounting transactions upload page

    # uploading accounting transactions xls
    When admin attaches accounting transactions xls for uploading
    And admin clicks on "Hochladen" button
    Then admin is on the accounting transactions upload page
    And admin sees message "Die Datei wurde hochgeladen und wird verarbeitet."

    # checking mismatched payments page
    When admin clicks on "Überprüfung Mismatches" link
    Then admin is on the mismatched payments list page
    And admin sees message "L111122221111222"
    And admin sees message "Joe"
    And admin sees message "Doe"
    And admin sees message "11223344"
    And admin sees message "23.05.2019"
    And admin sees message "50,84 €"
    And admin sees message "initial_commission"
    And admin sees message "Fonds Finanz"
    And admin sees message "Produktnummer (Vertragsnummer) nicht gefunden, Produkt ist nicht valide"

  @ignore
  @Flaky
  @requires_mandate
  Scenario: Retry to match success
    Given admin created products

    #admin upload xlsx
    When admin clicks on "Upload Abrechnung" link
    Then admin is on the accounting transactions upload page

    When admin attaches XLSX file exists with payments for that new product but wrong customer name
    And admin clicks on "Hochladen" button
    Then admin sees message "Die Datei wurde hochgeladen und wird verarbeitet."

    When admin clicks on "Überprüfung Mismatches" link
    Then admin is on the mismatched payments list page

    When admin clicks on product record edit button
    Then admin is on the mismatch_details page

    When admin fills "mismatched_payment_last_name" with customer_last_name
    And admin clicks on "aktualisieren" button
    Then admin doesn't see that mismatch

  @ignore
  @Flaky
  @requires_mandate
  Scenario: Retry to match failed
    Given admin created products

    #admin upload xlsx
    When admin clicks on "Upload Abrechnung" link
    Then admin is on the accounting transactions upload page

    When admin attaches XLSX file exists with payments for that new product but wrong customer name
    And admin clicks on "Hochladen" button
    Then admin sees message "Die Datei wurde hochgeladen und wird verarbeitet."

    When admin clicks on "Überprüfung Mismatches" link
    Then admin is on the mismatched payments list page

    When admin clicks on product record edit button
    Then admin is on the mismatch_details page

    When admin enters "very Wrong" into mismatched_payment_last_name input field
    And admin clicks on "aktualisieren" button
    Then admin does see that mismatch
