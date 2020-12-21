@ignore
@javascript
@desktop_only
Feature: Check links in OPS UI
  As an admin
  I want to be sure that all links are working in OPS UI

  Scenario Outline: Open entity details page using links in ops ui
    Given admin is logged in ops ui
    When admin clicks on <left_tab_link> link
    Then admin is on the <page_name> page
    When admin clicks on the test <entity_type> id in a table
    Then admin is on the <details_page_name> page
    Then admin sees text <text>

    Examples:
      | left_tab_link   | page_name     | entity_type | details_page_name   | text                    |
      | "Produkte"      | products      | product     | product_details     | "Beziehungen"           |
      | "Termine"       | appointments  | appointment | appointment_details | "Appointment"           |

    # TODO: probably, we must replace this two cases with assert sections in OPS UI pages tests
