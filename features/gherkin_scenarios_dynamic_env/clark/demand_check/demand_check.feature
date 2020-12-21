@javascript
Feature: Demandcheck and recommendations
  As a Clark customer
  I want to be able to complete the Demandcheck and obtain suitable recommendations

  @desktop_only
  Scenario Outline: user completes the Demandcheck and obtains suitable recommendations
    Given user is as the following
      | birthdate             |
      | <customer_birth_date> |

    And  user completes the mandate funnel with an inquiry
      | category | company |
      | Hausrat  | ACE     |

    And  user logs in with the credentials and closes "start demand check" modal

    # Demand Check Section
    When the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DemandcheckIntro           | control          |
    And  user clicks on "Bedarf" link
    Then user is on the demand check intro page
    And  user sees text "Der Clark Bedarfscheck"
    And  user sees 2 demandcheck trust icons
    And  user sees text "Optimiere deine Versicherungssituation"
    And  user sees text "2 Minuten"
    And  user sees text "9 Fragen"

    When user clicks on "Bedarfscheck starten" button
    Then user is on the demand check page
    Then user sees "Wo wohnst du" question label

      # Question 1
    When user selects "<living_place>" questionnaire option
    Then user sees "Planst du innerhalb der nächsten 12 Monate eine Immobilie zu (re-)finanzieren?" question label

      # Question 2
    When user selects "<house_building>" questionnaire option
    Then user sees "Besitzt du eines der folgenden Fahrzeuge?" question label

      # Question 3
    When user selects questionnaire options
      | option        |
      | <transport_1> |
      | <transport_2> |
    And  user clicks on "Weiter" button
    Then user sees "Wie ist deine Familiensituation?" question label

      # Question 4
    When user selects "<family_situation>" questionnaire option
    Then user sees "Hast du Kinder?" question label

      # Question 5
    When user selects "<children>" questionnaire option
    Then user sees "Was machst du beruflich?" question label

      # Question 6
    When user selects "<job>" questionnaire option
    And  user selects questionnaire suboptions
      | suboption         |
      | <job_suboption_1> |
      | <job_suboption_2> |
    And  user enters "<job_subtitle>" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Was machst du in deiner Freizeit?" question label

      # Question 7
    When user selects questionnaire options
      | option                |
      | <spare_time_option_1> |
      | <spare_time_option_2> |
    And  user clicks on "Weiter" button
    Then user sees "Hast du Tiere?" question label

      # Question 8
    When user selects questionnaire options
      | option  |
      | <pet_1> |
      | <pet_2> |
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label

      # Question 9
    When user enters "<salary>" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the recommendations page

      # Recommendations page
    When user closes "first recommendation" modal
    And user clicks on "Mehr anzeigen" button
    Then user sees "<recommendations>" recommendations in recommendation list

    Examples:
      | customer_birth_date | living_place                | house_building                                | transport_1 | transport_2 | family_situation    | children | job            | job_suboption_1                              | job_suboption_2                      | job_subtitle       | spare_time_option_1 | spare_time_option_2                             | pet_1 | pet_2 | salary | recommendations                                                                                                                                                                                                                                                                                               |
      | 01.01.1980          | Nichts davon                | Ja, ich plane eine Anschlussfinanzierung      | Nein        |             | Ich bin verheiratet | Nein     | Angestellter   | und verdiene bis zu 62.550 € Brutto jährlich | und bin gesetzlich krankenversichert | Softwareentwickler |                     |                                                 |       |       | 60000  | Privathaftpflicht~Rechtsschutzversicherung~Berufsunfähigkeitsversicherung~Krankenzusatzversicherung~Pflegezusatz (KV)~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Risikolebensversicherung~Gesetzliche Krankenversicherung                                                          |
      | 01.01.1968          | Nichts davon                | Nein                                          | Nein        |             | Ich bin verheiratet | Nein     | Angestellter   | und verdiene über 62.550 € Brutto jährlich   | und bin privat krankenversichert     | Softwareentwickler |                     |                                                 |       |       | 90000  | Privathaftpflicht~Rechtsschutzversicherung~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Pflegezusatz (KV)~Private Krankenversicherung                                                                                                                                                |
      | 01.01.1968          | Nichts davon                | Nein                                          | Nein        |             | Ich bin verheiratet | Nein     | Angestellter   | und verdiene über 62.550 € Brutto jährlich   | und bin gesetzlich krankenversichert | Softwareentwickler |                     |                                                 |       |       | 90000  | Privathaftpflicht~Rechtsschutzversicherung~Krankenzusatzversicherung~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Pflegezusatz (KV)                                                                                                                                                  |
      | 01.01.1970          | In einer gemieteten Wohnung | Nein                                          | Auto        | Motorrad    | Ich bin Single      | Nein     | Auszubildender |                                              |                                      | Abteilungsleiter   | Ich reise sehr viel | Ich arbeite gerne in Haus und Garten            | Hund  | Katze | 60000  | Privathaftpflicht~Tierhalter-Haftpflicht~Tier OP-Versicherung~Rechtsschutzversicherung~Motorradversicherung~KFZ-Absicherung~Dienstunfähigkeit~Berufsunfähigkeitsversicherung~Gesetzliche Krankenversicherung~Zahnzusatz~Krankenzusatzversicherung~Reiseversicherung~Unfallversicherung~Private Altersvorsorge |

  @desktop_only
  Scenario Outline: user completes the Demandcheck and obtains suitable recommendations for mortgage
    Given user is as the following
      | birthdate             |
      | <customer_birth_date> |

    And  user completes the mandate funnel with an inquiry
      | category | company |
      | Hausrat  | ACE     |

    And  user logs in with the credentials and closes "start demand check" modal

    # Demand Check Section
    When the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DemandcheckIntro           | control          |
    And  user clicks on "Bedarf" link
    Then user is on the demand check intro page
    And  user sees text "Der Clark Bedarfscheck"
    And  user sees 2 demandcheck trust icons
    And  user sees text "Optimiere deine Versicherungssituation"
    And  user sees text "2 Minuten"
    And  user sees text "9 Fragen"

    When user clicks on "Bedarfscheck starten" button
    Then user is on the demand check page
    Then user sees "Wo wohnst du" question label

      # Question 1
    When user selects "<living_place>" questionnaire option
    Then user sees "Planst du innerhalb der nächsten 12 Monate eine Immobilie zu (re-)finanzieren?" question label
    And user selects "<house_building>" questionnaire option

    When user sees "Hast du bereits deine Traum-Immobilie gefunden und suchst nun eine Finanzierungsmöglichkeit?" question label
    Then user selects "Ja" questionnaire option

      # Question 2
    When user sees "Besitzt du eines der folgenden Fahrzeuge?" question label

      # Question 3
    When user selects questionnaire options
      | option        |
      | <transport_1> |
      | <transport_2> |
    And  user clicks on "Weiter" button
    Then user sees "Wie ist deine Familiensituation?" question label

      # Question 4
    When user selects "<family_situation>" questionnaire option
    Then user sees "Hast du Kinder?" question label

      # Question 5
    When user selects "<children>" questionnaire option
    Then user sees "Was machst du beruflich?" question label

      # Question 6
    When user selects "<job>" questionnaire option
    And  user selects questionnaire suboptions
      | suboption         |
      | <job_suboption_1> |
      | <job_suboption_2> |
    And  user enters "<job_subtitle>" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Was machst du in deiner Freizeit?" question label

      # Question 7
    When user selects questionnaire options
      | option                |
      | <spare_time_option_1> |
      | <spare_time_option_2> |
    And  user clicks on "Weiter" button
    Then user sees "Hast du Tiere?" question label

      # Question 8
    When user selects questionnaire options
      | option  |
      | <pet_1> |
      | <pet_2> |
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label

      # Question 9
    When user enters "<salary>" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the recommendations page

      # Recommendations page
    When user closes "first recommendation" modal
    And user clicks on "Mehr anzeigen" button
    Then user sees "<recommendations>" recommendations in recommendation list

    Examples:
      | customer_birth_date | living_place                | house_building                                | transport_1 | transport_2 | family_situation    | children | job            | job_suboption_1                              | job_suboption_2                      | job_subtitle       | spare_time_option_1 | spare_time_option_2                             | pet_1 | pet_2 | salary | recommendations                                                                                                                                                                                                                                        |
      | 01.01.1980          | Nichts davon                | Ja, ich plane eine Immobilie zu finanzieren   | Nein        |             | Ich bin Single      | Nein     | Angestellter   | und verdiene bis zu 62.550 € Brutto jährlich | und bin gesetzlich krankenversichert | Softwareentwickler |                     |                                                 |       |       | 60000  | Privathaftpflicht~Rechtsschutzversicherung~Berufsunfähigkeitsversicherung~Krankenzusatzversicherung~Pflegezusatz (KV)~Unfallversicherung~Betriebliche Altersvorsorge~Private Altersvorsorge~Gesetzliche Krankenversicherung~Risikolebensversicherung   |

  @ignore
  @requires_mandate
  Scenario: user is presented with the new demandcheck intro and demandcheck modal
    Given the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DoDemandcheckModal         | v1               |
      | 2020Q3DemandcheckIntro           | v1               |

    # Assert new demand check modal
    When user logs in with the credentials
    Then user sees text "Bist du optimal versichert?"
    And  user sees text " In nur 2 Minuten erfährst du welche Versicherungen dich optimal schützen – und welche nicht."
    And  user sees that "Starte deinen Bedarfscheck" button is visible
    And  user sees that "Erinnere mich später" button is visible

    # Assert new demand check intro
    When user clicks on "Erinnere mich später" button
    And  user clicks on "Bedarf" link
    Then user is on the demand check intro page
    And  user sees text "Bist du schon optimal versichert?"
    And  user sees text "In nur 2 Minuten erfährst du welche Versicherungen dich optimal schützen – und welche nicht."
    And  user sees that "Starte deinen Bedarfscheck" button is visible
    And  user sees 2 demandcheck trust icons

    When user clicks on "Starte deinen Bedarfscheck" button
    Then user is on the demand check page
    And  user sees "Wo wohnst du" question label

  @ignore
  @requires_mandate
  Scenario: user is able to start demand check from the new demand check modal
    Given the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DoDemandcheckModal         | v1               |
      | 2020Q3DemandcheckIntro           | v1               |
    When user logs in with the credentials
    Then user sees text "Bist du optimal versichert?"
    And  user sees text " In nur 2 Minuten erfährst du welche Versicherungen dich optimal schützen – und welche nicht."
    And  user sees that "Starte deinen Bedarfscheck" button is visible
    And  user sees that "Erinnere mich später" button is visible

    # Assert user is able to start demand check from the modal
    When user clicks on "Starte deinen Bedarfscheck" button
    Then user is on the demand check page
    And  user sees "Wo wohnst du" question label
