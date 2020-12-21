@javascript
@desktop_only
@products
@wip
Feature: Determination of correct percentages for deductions
  As an admin
  I want to see the deductions to be automatically calculated

  Background:
    Given admin is logged in ops ui
    When admin clicks on "Produkte" link
    Then admin is on the products page

  Scenario: Show deductions configured by subcompany
    Given a subcompany with "fonds_finanz" configured as broker pool
    And there is a commission rate for "FondsFinanz" with 10% as deduction reserve sales and 0% as deduction fidelity sales
    When admin accesses product edition view
    Then admin sees the deductions

  Scenario: Calculate deductions based on subcompany
    Given a subcompany with "FondsFinanz" configured as broker pool
    And there is a commission rate for "FondsFinanz" with 10% as deduction reserve sales and 0% as deduction fidelity sales
    And admin accesses product edition view
    And admin sets 1000 as aquisition value
    Then admin sees 100 for cancellation reserve
    And admin sees 0 for trust damage liability
    And admin sees 900 for net payout amount

  Scenario: Show deductions configured by product
    Given a product with "FondsFinanz" configured as sales channel
    And there is a commission rate for "FondsFinanz" with 10% as deduction reserve sales and 0% as deduction fidelity sales
    When admin accesses product edition view
    Then admin sees the deductions
