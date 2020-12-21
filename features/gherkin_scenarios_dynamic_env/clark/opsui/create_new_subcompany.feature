@javascript
@desktop_only
Feature: Create a new subcompany in OPS UI
  As an admin
  I want to be able to create a new plan

  Background:
    Given admin is logged in ops ui
    When admin clicks on "Gruppen" link
    And admin clicks on "Gesellschaften" link
    Then admin is on the subcompanies page

  Scenario Outline: Create a new subcompany
    When admin clicks on "Gesellschaft hinzufügen" link
    And admin is on the new subcompany page
    And admin enters "<name>" into Name input field
    And admin selects "<group>" as the subcompany group
    And admin selects "<vertical>" as the subcompany vertical
    And admin clicks on "<new_contract_management_channel>" within group "Standardanbindung BP"
    And admin clicks on "<new_contract_sales_channel>" within group "Standardanbindung AP"
    And admin clicks on "Anlegen" button

    Then admin sees message "Gesellschaft wurde erfolgreich erstellt."

  Examples:
    | name                  | group | vertical      | new_contract_management_channel | new_contract_sales_channel |
    | Cucumber Subcompany   | ACE   | Pensionsfonds | FondsFinanz                     | FondsFinanz                |
    | Cucumber Subcompany 2 | ACE   | Pensionsfonds | QualityPool (Hypoport)          | Direktanbindung            |
    | Cucumber Subcompany 3 | ACE   | Pensionsfonds | Direktanbindung                 | QualityPool (Hypoport)     |
