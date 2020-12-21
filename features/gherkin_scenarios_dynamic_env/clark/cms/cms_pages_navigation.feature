@smoke
@cms
@javascript
Feature: CMS pages navigation
  As a user
  I want to navigate through the Clark site using links on the pages

  Scenario: User opens Clark home page and goes to "how it works" page
    Given user navigates to home page
    Then  user is on the home page

    When user clicks on "So funktioniert’s" link
    Then user is on the how it works page
    And  user sees that the page title is "CLARK - So funktioniert's"

  @desktop_only
  Scenario Outline: User opens Clark home page and navigates through CMS pages
    Given user navigates to home page
    Then  user is on the home page

    When  user opens versicherungen menu
    And   user scrolls to and clicks on "<navigation_drop_down_link>" link
    Then  user is on the <page_name> page
    And   user sees that the page title is "<page_title>"
    And   user sees text <text>

    Examples:
      | navigation_drop_down_link          | page_name                       | text                             | page_title                                                           |
      | Privathaftpflicht­versicherung     | privathaftpflicht               | "Haftpflichtversicherungen"      | Eine wichtige Versicherung: Haftpflicht \| CLARK                   |
      | Hausratversicherung                | hausratversicherung             | "Hausratversicherung"            | Hausratversicherung: Vergleiche die besten Angebote \| CLARK         |
      | Kfz-Versicherung                   | kfz-versicherung                | "Kfz-Versicherung"               | Die richtige Kfz-Versicherung finden \| CLARK                        |
      | Rechtsschutzversicherung           | rechtsschutzversicherung        | "Rechtsschutzversicherung"       | Rechtsschutzversicherung vergleichen \| CLARK                        |
      | Berufsunfähigkeitsversicherung     | berufsunfaehigkeitsversicherung | "Berufsunfähigkeitsversicherung" | Berufsunfähigkeitsversicherung – richtig versichern \| CLARK         |
      | Betriebliche Altersvorsorge        | betriebliche-altersvorsorge     | "Betriebliche Altersvorsorge"    | Betriebliche Altersvorsorge: Infos zur Betriebsrente                 |
      | Private Rentenversicherung         | private-rentenversicherung      | "Private Rentenversicherung "    | Private Rentenversicherung: Die 3. Säule der Vorsorge                |
      | Risikolebensversicherung           | risikoleben                     | "Risikolebensversicherung "      | Risikolebensversicherung: Absicherung der Familie \| CLARK           |
      | Sterbegeldversicherung             | sterbegeldversicherung          | "Sterbegeldversicherung "        | Sterbegeldversicherung: Angehörige finanziell absichern \| CLARK     |
      | Gesetzliche Pflegeversicherung     | pflegeversicherung              | "Soziale Pflegeversicherung"     | Pflegeversicherung: Basisabsicherung für alle \| CLARK               |
      | Pflegezusatzversicherung           | pflegezusatzversicherung        | "Pflegezusatzversicherung"       | Pflegezusatzversicherung: Vorsorge für den Pflegefall \| CLARK       |
      | Auslandskrankenversicherung        | auslandskrankenversicherung     | "Auslandskrankenversicherung"    | Reisekrankenversicherung und Auslandsversicherung \| CLARK           |
      | Zahnzusatzversicherung             | zahnzusatzversicherung          | "Zahnzusatzversicherung"         | Zahnzusatzversicherung: Was es zu beachten gilt \| CLARK             |
      | Die richtige Altersvorsorge finden | altersvorsorge                  | "Die richtige Altersvorsorge"    | Die richtige Altersvorsorge für den Ruhestand finden \| CLARK        |
      | Riester-Rente                      | riester-rente                   | "Riester-Rente"                  | Riester-Rente: Für wen sich die Altersvorsorge lohnt \| CLARK        |
      | Rürup-Rente                        | ruerup-rente                    | "Rürup-Rente"                    | Rürup-Rente: Vor- und Nachteile dieser Altersvorsorge \| CLARK       |
      | Private Altersvorsorge             | private-altervorsorge           | "Private Altersvorsorge"         | Private Altersvorsorge: Alles Wissenswerte \| CLARK                  |
      | Krankenkassenwechsel               | krankenkassenwechsel            | "Krankenkassenwechsel"           | Krankenkassenwechsel: Fristen, Prämien und Leistungen \| CLARK       |
      | Private Krankenversicherung        | private krankenversicherung     | "Private Krankenversicherung"    | Die Private Krankenversicherung \| CLARK                             |
    # | Wo hilft die Versicherung          | coronavirus-versicherungsfragen | "Coronavirus in Deutschland"     | Coronavirus in Deutschland: CLARK klärt Versicherungsfragen          |


  Scenario Outline: User opens Clark home page and navigates through AGB, ueber-uns, Erstinformation, Impressum and Datenschutz pages
    Given user navigates to home page
    Then  user is on the home page

    When user clicks on "<navigation_link>" link
    Then user is on the <pagename> page
    And  user sees that the page title is "<pagetitle>"

    Examples:
      | navigation_link | pagename        | pagetitle                                      |
      | Über uns        | ueber-uns       | CLARK - Über uns                               |
      | AGB             | agb             | Allgemeine Geschäftsbedingungen - AGB \| Clark |
      | Erstinformation | erstinformation | Erstinformation \| Clark                       |
      | Impressum       | impressum       | Impressum I Clark                              |
      | Datenschutz     | datenschutz     | Erklärung zum Datenschutz \| Clark             |

  @desktop_only
  Scenario: User opens Clark home page and requests and advice for Sterbegeldversicherung via leadgenModal
    Given user navigates to home page
    Then  user is on the home page

    When  user opens versicherungen menu
    And   user clicks on "Sterbegeldversicherung" link
    Then  user is on the sterbegeldversicherung page

    When  user clicks on "Beratung anfordern" link
    Then  user sees "sterbegeldversicherung" modal

    When  user enters "LeadgenModal" into first_name input field
    And   user enters "testing" into last_name input field
    And   user enters "leadgenmodaltest@clark.de" into email input field
    And   user enters "017623380481" into phone_number input field
    And   user selects lead gen checkbox
    And   user clicks on "Bestätigen" button
    Then  user is on the success page
    And   user sees text "Vielen Dank für dein Interesse"

  # https://clarkteam.atlassian.net/browse/JCLARK-57785 covers bugfix
  @requires_mandate
  Scenario: User logged in application and clicks at cms page
    Given user logs in with the credentials and closes "start demand check" modal
    And   user is on the manager page

    When user navigates to payback page
    Then user is on the payback page

    When user opens cms burger menu [mobile view only]
    And  user clicks on "Mein Konto" link
    Then user is on the manager page

  Scenario: User logged in application and navigates to careers page
    Given user navigates to home page
    Then  user is on the home page

    When user clicks on "Karriere" link
    Then user is on the karriere page
    And  user sees text "Life is short, work somewhere awesome."

    When user clicks on "See open roles" link
    Then user is on the jobs page
    And  user sees that the page title is "Jobs & Stellenangebote bei Clark - Der Versicherungsmanager"
    And  user sees text "Arbeiten bei Clark"
