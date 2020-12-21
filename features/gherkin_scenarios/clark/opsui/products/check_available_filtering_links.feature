@javascript
@desktop_only
@products
@stagings_only
Feature: Check available filter links on product list page
  As an admin
  I want to filter products by available states

  Background:
    Given admin is logged in ops ui

  Scenario: Hide self service customer flow states
    Given app feature "self_service_products" is off
    When admin clicks on "Produkte" link
    Then admin sees that links are not visible
    | Details fehlend        | /admin/products?by_status=details_missing  |
    | Analyse laufend        | /admin/products?by_status=under_analysis   |
    | Analyse fehlgeschlagen | /admin/products?by_status=analysis_failed  |
    | Details komplett       | /admin/products?by_status=details_complete |
