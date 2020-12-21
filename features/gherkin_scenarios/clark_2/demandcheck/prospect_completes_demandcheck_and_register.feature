@javascript
Feature: Prospect customer completes demand check and then register
  As a prospect customer
  I want to complete demand check and then register

  @desktop_only
  @smoke
  Scenario Outline: Prospect customer completes demand check and then register
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    When user navigates to clark 2 starting page
    Then user is on the clark 2 contract adding exploration page

    When the local storage item clark-experiments has the following values
      | business-strategy                | clark2           |
    And  user clicks on "Bedarf" link
    Then user is on the clark 2 recommendations page
    And  user sees text "Optimiere deine Versicherungssituation"

    When user clicks on "Jetzt starten" link
    Then user is on the demand check page
    And  user sees "Wann bist du geboren?" question label

    # Question 1
    When user enters "<customer_birth_date>" into birth date input field
    And  user clicks on "Weiter" button
    Then user sees "Was ist dein Geschlecht?" question label

    # Question 2
    When user selects "Männlich" questionnaire option
    Then user sees "Wo wohnst du" question label

    # Question 3
    When user selects "<living_place>" questionnaire option
    Then user sees "Planst du innerhalb der nächsten 12 Monate eine Immobilie zu (re-)finanzieren?" question label

    # Question 4
    When user selects "<house_building>" questionnaire option
    Then user sees "Besitzt du eines der folgenden Fahrzeuge?" question label

    # Question 5
    When user selects questionnaire options
      | option        |
      | <transport_1> |
      | <transport_2> |
    And  user clicks on "Weiter" button
    Then user sees "Wie ist deine Familiensituation?" question label

    # Question 6
    When user selects "<family_situation>" questionnaire option
    Then user sees "Hast du Kinder?" question label

    # Question 7
    When user selects "<children>" questionnaire option
    Then user sees "Was machst du beruflich?" question label

    # Question 8
    When user selects "<job>" questionnaire option
    And  user selects questionnaire suboptions
      | suboption         |
      | <job_suboption_1> |
      | <job_suboption_2> |
    And  user enters "<job_subtitle>" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Was machst du in deiner Freizeit?" question label

    # Question 9
    When user selects questionnaire options
      | option                |
      | <spare_time_option_1> |
      | <spare_time_option_2> |
    And  user clicks on "Weiter" button
    Then user sees "Hast du Tiere?" question label

    # Question 10
    When user selects questionnaire options
      | option  |
      | <pet_1> |
      | <pet_2> |
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label

    # Question 11
    When user enters "<salary>" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the clark 2 registration page
    And  user sees text "Sichere deinen Fortschritt"
    And  user sees email address input field
    And  user sees password input field

    When user enters their email address data
    And  user enters their password data
    And  user clicks on "Jetzt registrieren" button
    Then user is on the clark 2 recommendations rewards page
    And  user sees text "Deine Empfehlungen sind verfügbar"

    When user clicks on "Empfehlungen ansehen" link
    Then user is on the recommendations page

    When user closes "first recommendation" modal
    And user clicks on "Mehr anzeigen" button
    Then user sees "<recommendations>" recommendations in recommendation list

    Examples:
      | customer_birth_date | living_place                | house_building                              | transport_1 | transport_2 | family_situation    | children | job            | job_suboption_1                              | job_suboption_2                      | job_subtitle       | spare_time_option_1 | spare_time_option_2                             | pet_1 | pet_2 | salary | recommendations                                                                                                                                                                                                                                                                                                                 |
      | 01.01.1980          | Nichts davon                | Nein                                        | Nein        |             | Ich bin Single      | Nein     | Angestellter   | und verdiene bis zu 62.550 € Brutto jährlich | und bin gesetzlich krankenversichert | Softwareentwickler |                     |                                                 |       |       | 60000  | Privathaftpflicht~Rechtsschutzversicherung~Berufsunfähigkeitsversicherung~Krankenzusatzversicherung~Pflegezusatz (KV)~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Gesetzliche Krankenversicherung                                                                                                     |
      | 01.01.1980          | Nichts davon                | Nein                                        | Nein        |             | Ich bin verheiratet | Nein     | Angestellter   | und verdiene bis zu 62.550 € Brutto jährlich | und bin gesetzlich krankenversichert | Softwareentwickler |                     |                                                 |       |       | 60000  | Privathaftpflicht~Rechtsschutzversicherung~Berufsunfähigkeitsversicherung~Krankenzusatzversicherung~Pflegezusatz (KV)~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Risikolebensversicherung~Gesetzliche Krankenversicherung                                                                            |
      | 01.01.1968          | Nichts davon                | Nein                                        | Nein        |             | Ich bin verheiratet | Nein     | Angestellter   | und verdiene über 62.550 € Brutto jährlich   | und bin privat krankenversichert     | Softwareentwickler |                     |                                                 |       |       | 90000  | Privathaftpflicht~Rechtsschutzversicherung~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Pflegezusatz (KV)~Private Krankenversicherung                                                                                                                                                                  |
      | 01.01.1968          | Nichts davon                | Nein                                        | Nein        |             | Ich bin verheiratet | Nein     | Angestellter   | und verdiene über 62.550 € Brutto jährlich   | und bin gesetzlich krankenversichert | Softwareentwickler |                     |                                                 |       |       | 90000  | Privathaftpflicht~Rechtsschutzversicherung~Krankenzusatzversicherung~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Pflegezusatz (KV)                                                                                                                                                                    |
      | 01.01.1950          | In einer gemieteten Wohnung | Ja, ich plane eine Anschlussfinanzierung    | Auto        | Motorrad    | Ich bin Single      | Nein     | Auszubildender |                                              |                                      | Abteilungsleiter   | Ich reise sehr viel | Ich verbringe sehr viel Zeit mit meiner Familie | Hund  | Katze | 60000  | Privathaftpflicht~Tierhalter-Haftpflicht~Tier OP-Versicherung~Hausrat~Rechtsschutzversicherung~Reiseversicherung~Motorradversicherung~KFZ-Absicherung~Berufsunfähigkeitsversicherung~Gesetzliche Krankenversicherung~Zahnzusatz~Krankenzusatzversicherung~Unfallversicherung~Risikolebensversicherung                           |
