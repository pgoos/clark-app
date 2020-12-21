@javascript
@desktop_only
Feature: Check commission percentages in opsui
  As an admin
  I want to be able to check that correct commission rates are being applied to correct pools

  Scenario: Verify correct commission rate is set for FondsFinanz

    # login to ops ui and navigate to commission rates page
    Given admin is logged in ops ui
    When admin clicks on "Provisionen" link
    Then admin is on the commission rates page

    When admin clicks on "Provision hinzufügen" link
    Then admin is on the new commission rates page

    # Verify default commission rates of pools
    When admin selects "FondsFinanz" as the commission rate sales channel
    Then admin sees 10.0 as default "fonds finanz" commission rate

    When admin selects "Qualitypool" as the commission rate sales channel
    Then admin sees 0.0 as default "quality pool" commission rate

    When admin selects "Direktanbindung" as the commission rate sales channel
    Then admin sees 0.0 as default "direct agreement" commission rate
