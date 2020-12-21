@javascript
@desktop_only
Feature: Search mandates in OPS UI right panel by last name (with umlauts)
  As an admin
  I want to be able to search mandates

  @ignore
  @Flaky
  Scenario: Search mandates in the right search panel
    # create a mandates with an inquiry
    Given user is as the following
      | first_name | last_name      |
      | Clark1     | Muller         |

    When user completes the mandate funnel with an inquiry
      | category                 | company |
      | Rechtsschutzversicherung | Asstel  |

    Given user is as the following
      | first_name | last_name      |
      | Clark2     | Müller         |

    When user completes the mandate funnel with an inquiry
      | category                 | company |
      | Rechtsschutzversicherung | Asstel  |

    Given user is as the following
      | first_name | last_name      |
      | Clark3     | Mueller        |

    When user completes the mandate funnel with an inquiry
      | category                 | company |
      | Rechtsschutzversicherung | Asstel  |

    Given admin is logged in ops ui

    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    # search with umlaut

    When admin search by last_name with the term "Müller"
    And admin clicks on "right column search" button
    Then admin is on the mandates page
    And admin sees text "Müller"
    And admin sees text "Mueller"
    But admin doesn't see text "Muller"

    # search with predicted umlaut

    When admin search by last_name with the term "Mueller"
    And admin clicks on "right column search" button
    Then admin is on the mandates page
    And admin sees text "Müller"
    And admin sees text "Mueller"
    But admin doesn't see text "Muller"

    # search without umlaut

    When admin search by last_name with the term "Muller"
    And admin clicks on "right column search" button
    Then admin is on the mandates page
    And admin sees text "Muller "
    But admin doesn't see text "Müller"
    But admin doesn't see text "Mueller"
