@javascript
Feature: Single Recommendation Page Verification
  As a Clark user
  I want to see all data on recommendation category detail page

  @requires_mandate
  Scenario Outline: User sees complete category information on single recommendation page
    Given user logs in with the credentials and closes "start demand check" modal
    And  user completes the demand check

    When user closes "first recommendation" modal
    And user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "<category>"
    Then user is on the single recommendation page
    And  user sees "<category>" category title label
    And  user sees category importance tag label
    And  user sees text "<description>"
    And  user sees that "Unverbindliches Angebot anfordern" button is visible
    And  user sees that "Bestehenden Vertrag hinzufügen" button is visible
    And  user sees statistics map image
    And  user sees text "<accident_card>"
    And  user sees the quality standard section with <icons_quantity> icons
    And  user sees Why Clark footer section with following content
      | content                                                                                                                                                                                                 |
      | Warum Clark?                                                                                                                                                                                            |
      | Maßstäbe zur Anbieter-Auswahl                                                                                                                                                                           |
      | Bei Vergleichsportalen sind häufig nur Standardleistungen mit abgesichert. Der Verzicht auf die grobe Fahrlässigkeit ist ein sehr wichtiger Punkt, der bei vielen Tarifen nicht mit eingeschlossen ist. |
      | Die Clark-Garantie                                                                                                                                                                                      |
      | Kein Risiko                                                                                                                                                                                             |
      | Der Vertrag ist 14 Tage widerrufbar                                                                                                                                                                     |
      | Bequem                                                                                                                                                                                                  |
      | Schnell und einfach online beantragen                                                                                                                                                                   |
      | Transparent                                                                                                                                                                                             |
      | Keine zusätzlichen Kosten                                                                                                                                                                               |

    Examples:
      | category                       | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | icons_quantity | accident_card                                                                                                                                                                                                                                                                                                                                                                                                       |
      | Privathaftpflicht              | Eine private Haftpflichtversicherung sichert dich gegen Schadensforderungen Dritter ab, insbesondere Personenschäden, Sachschäden und meist Vermögensschäden. Unberechtigte Forderungen werden abgewehrt, sodass du gleichzeitig einen passiven Rechtsschutz genießt.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | 7              | Ein typischer Schadensfall: Kinder spielen Fußball und der Ball rollt auf die Straße. Ein Auto weicht aus und fährt in eine Laterne. Dabei entsteht am Auto ein Schaden in Höhe von 10.000€.                                                                                                                                                                                                                        |
      | Berufsunfähigkeitsversicherung | Deine Arbeitskraft ist im Beruf dein Kapital. Doch was in jungen Jahren selbstverständlich ist, kann sich während des Berufslebens schnell ändern. Ein Unfall, Allergien oder eine schwere Krankheit: Viele Ursachen können dich aus dem Arbeitsleben reißen und dein Einkommen und somit deinen Lebensstandard gefährden. Die staatlichen Leistungen sind gering und reichen nicht aus, um deinen Lebensstandard zu sichern. Junge Versicherte profitieren von günstigen Einstiegskonditionen.                                                                                                                                                                                                                                                             | 4              | Du hast jahrelang gearbeitet und leidest nun unter chronischen Rückenbeschwerden, unter denen du nur noch weniger als 3 Stunden in deinem Beruf arbeiten kannst. Dein Arzt attestiert, das dieser Zustand länger als 6 Monate anhalten wird. Die Berufsunfähigkeitsversicherung wird dir anstandslos die volle vereinbarte Berufsunfähigkeitsrente auszahlen, solange sich dein Zustand nicht erheblich verbessert. |
      | Private Altersvorsorge         | Die gesetzliche Rente reicht alleine nicht aus. Du erhältst ca. 48% deines derzeitigen Gehaltes und darauf müssen auch noch Steuern gezahlt werden. Mit einer privaten Altersvorsorge kannst du dir im Alter deinen derzeitigen Lebensstandard sichern. Ob staatliche Förderung, oder Renditechancen – es gibt flexible Möglichkeiten, die Versicherung den persönlichen Vorstellungen und dem Bedarf anzupassen. Je nach Form der Absicherung, kann man Sonderzahlungen leisten um eine höhere Rente zu erhalten oder ob das Kapital ganz oder teilweise ausgezahlt wird. Im Falle eines finanziellen Engpasses ist es oftmals möglich die Beitragszahlung auszulassen. Generell, eine sinnvolle und sichere Ergänzung zur gesetzlichen Absicherung.       | 4              | Die gesetzliche Rentenversicherung deckt zukünftig nach Schätzungen nur 40% des letzten Bruttogehalts. Daher solltest du privat vorsorgen, um deinen aktuellen Lebensstandard aufrechtzuerhalten. Die Private Altersvorsorge ist ein langfristiger Vermögensaufbau und hat zahlreiche Durchführungswege.                                                                                                            |
