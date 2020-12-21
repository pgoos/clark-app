# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id                           :integer          not null, primary key
#  state                        :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  vertical_id                  :integer
#  ident                        :string           not null
#  coverage_features            :jsonb            not null
#  icon                         :string
#  starting_price_cents         :integer
#  starting_price_currency      :string           default("EUR")
#  content_page_href            :string
#  description                  :text
#  background_image             :string
#  background_image_mobile      :string
#  search_tokens                :string
#  overview_image_short         :string
#  overview_image_long          :string
#  termination_period           :integer
#  priority                     :integer          default(1)
#  average_price_cents          :integer
#  average_price_currency       :string           default("EUR")
#  cover_benchmark              :integer
#  product_detail_image_file_id :integer
#  ff_type                      :string
#  premium_type                 :string           default("gross")
#  questionnaire_id             :integer
#  advice_templates             :jsonb
#  included_category_ids        :integer          default([]), is an Array
#  category_type                :string           default("regular")
#  simple_checkout              :boolean          default(FALSE)
#  offer_templates              :jsonb
#  metadata                     :jsonb
#  life_aspect                  :string
#  profit_margin                :integer          default("unspecified")
#  plan_filter_id               :integer
#  tax_rate                     :float
#  discontinued                 :boolean          default(FALSE)
#

HR_COVERAGE_FEATURES = [
  {
    name: "Selbstbeteiligung",
    genders: %w[male female],
    definition: "in Euro",
    identifier: "slbstd5eecfaa79ef042e",
    value_type: "Money"
  },
  {
    name: "Fahrradschutz",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "fhrrd1f2777d12624a43a",
    value_type: "Money"
  },
  {
    name: "Rund um die Uhr",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "fhrrd045ed58071f20932",
    value_type: "Boolean"
  },
  {
    name: "Überspannungsschäden",
    genders: %w[male female],
    definition: "in Euro",
    identifier: "Übrspfeda49333e8cebbd",
    value_type: "Money"
  },
  {
    name: "Versicherungssumme",
    genders: %w[male female],
    definition: "in Euro",
    identifier: "vrschbd36a7ca8132b582",
    value_type: "Money"
  },
  {
    name: "Wertsachen",
    genders: %w[male female],
    definition: "in Euro",
    identifier: "wrtsc60a996886521a228",
    value_type: "Money"
  },
  {
    name: "Verzicht auf Einrede der groben Fahrlässigkeit",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "vrzch5d2fe4b54cb4f879",
    value_type: "Boolean"
  },
  {
    name: "Außenversicherung",
    genders: %w[male female],
    definition: "Betrag",
    identifier: "ßnvrsf36db3f41b937dcd",
    value_type: "Text"
  },
  {
    name: "Glasversicherung",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "glsvre9ea245163a7f933",
    value_type: "Boolean"
  },
  {
    name: "Elementarschäden",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "lmntr7aa8042d2e9733e4",
    value_type: "Boolean"
  },
  {
    name: "Überschwemmung",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "Übrsc6a828792808434a7",
    value_type: "Boolean"
  },
  {
    name: "Diebstahl aus Kfz",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "dbsthb16faf171ce0b328",
    value_type: "Boolean"
  },
  {
    name: "Taschen- und Trickdiebstahl",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "tschn0f1662d77e717962",
    value_type: "Boolean"
  },
  {
    name: "Sengschäden",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "sngsc74c364097eff9371",
    value_type: "Boolean"
  },
  {
    name: "Vom Mieter eingefügte Gegenstände",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "vmmtr23f32c218427dd3d",
    value_type: "Boolean"
  },
  {
    name: "Sachen in gewerbl. genutzten Räumen",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "schnn5d26241aba9d0628",
    value_type: "Boolean"
  },
  {
    name: "Hotelkosten bei Unbewohnbarkeit",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "htlks3c590aea79a5d971",
    value_type: "Boolean"
  },
  {
    name: "Sachverständigenkosten",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "schvrca32230784793927",
    value_type: "Boolean"
  },
  {
    name: "Schlossänderungskosten",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "schls54295b404cb6b5f4",
    value_type: "Boolean"
  },
  {
    name: "Umzugskosten bei Unbewohnbarkeit",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "mzgsk392b496758e8998e",
    value_type: "Boolean"
  },
  {
    name: "Versicherte Gefahren",
    genders: %w[male female],
    definition: "Feuer / Leitungswasser / Einbruchdiebstahl / Sturm ",
    identifier: "vrsch4fc13db206c7a961",
    value_type: "Text"
  },
  {
    name: "Größe der Wohnung (qm)",
    genders: %w[male female],
    definition: "qm",
    identifier: "text_grdrwhnngqm_d7337e",
    value_type: "Text"
  },
  {
    name: "Diebstahl von Kinderwagen",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_dbsthlvnkndrwgn_2d4597",
    value_type: "Boolean"
  },
  {
    name: "Diebstahl von Rollstühlen",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_dbsthlvnrllsthln_9c4b95",
    value_type: "Boolean"
  },
  {
    name: "Diebstahl von Sachen vom Grundstück",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_dbsthlvnschnvmgrndstck_13cb52",
    value_type: "Boolean"
  },
  {
    name: "Diebstahl aus Krankenzimmern",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_dbsthlskrnknzmmrn_78497d",
    value_type: "Boolean"
  },
  {
    name: "Taschen- und Trickdiebstahl",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_tschnndtrckdbsthl_41e70c",
    value_type: "Boolean"
  },
  {
    name: "Schäden an Gefrier- und Kühlgut",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_schdnngfrrndkhlgt_9cabb3",
    value_type: "Boolean"
  },
  {
    name: "Rauch- und Rußschäden",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_rchndrschdn_2485c2",
    value_type: "Boolean"
  },
  {
    name: "Sengschäden",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_sngschdn_e98be9",
    value_type: "Boolean"
  },
  {
    name: "Rückstauschäden (ohne Abschluss Elementar)",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_rckstschdnhnbschlsslmntr_4a8efa",
    value_type: "Boolean"
  },
  {
    name: "Wasserschäden durch Aquarien",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_wssrschdndrchqrn_8e9fe0",
    value_type: "Boolean"
  },
  {
    name: "Wasserschäden durch Wasserbetten",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_wssrschdndrchwssrbttn_1bee27",
    value_type: "Boolean"
  },
  {
    name: "Vom Mieter eingefügte Gegenstände",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_vmmtrngfgtggnstnd_21ee31",
    value_type: "Boolean"
  },
  {
    name: "Sachen in gewerbl. genutzten Räumen",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_schnngwrblgntztnrmn_0b1c40",
    value_type: "Boolean"
  },
  {
    name: "Auslandsrückholkosten",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_slndsrckhlkstn_85cdb8",
    value_type: "Boolean"
  },
  {
    name: "Haustierbetreuung",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_hstrbtrng_46a710",
    value_type: "Boolean"
  },
  {
    name: "Hotelkosten bei Unbewonbarkeit",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_htlkstnbnbwnbrkt_cd740d",
    value_type: "Boolean"
  },
  {
    name: "Sachverständigenkosten",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_schvrstndgnkstn_27d4f2",
    value_type: "Boolean"
  },
  {
    name: "Schlossänderungskosten",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_schlssndrngskstn_ca84f9",
    value_type: "Boolean"
  },
  {
    name: "Umzugskosten bei Unbewohnbarkeit",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_mzgskstnbnbwhnbrkt_8e5b5c",
    value_type: "Boolean"
  }
].freeze

GKV_COVERAGE_FEATURES = [
  {
    name: "24/7-Servicetelefon ",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_247srvctlfn_4d2186",
    value_type: "Text"
  },
  {
    name: "Infohotline",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_mdznschnfhtlnfrvrschrt_8efaf7",
    value_type: "Text"
  },
  {
    name: "Terminvermittlung",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_ngbtfrvrmttlngvnrzttrmnn_d647cc",
    value_type: "Text"
  },
  {
    name: "Service in Englisch",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_frmdsprchgrkndnsrvcnglsch_4ebe2a",
    value_type: "Text"
  },
  {
    name: "Bonus für Mitgliedschaft im Fitnessstudio",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "boolean_bnsfrmtgldschftmftnssstd_e3494c",
    value_type: "Text"
  },
  {
    name: "Brustkrebsfrüherkennung",
    genders: ["female"],
    definition: "Ja (ggf. mit Kommentar) / Nein",
    identifier: "text_brstkrbsfrhrknnng_4de026",
    value_type: "Text"
  },
  {
    name: "Darmkrebsfrüherkennung",
    genders: ["male"],
    definition: "Ja (ggf. mit Kommentar) / Nein",
    identifier: "text_drmkrbsfrhrknnng_4a4179",
    value_type: "Text"
  },
  {
    name: "Freie Krankenhauswahl",
    genders: %w[male female],
    definition: "Ja / Nein",
    identifier: "boolean_frkrnknhswhl_6d0aeb",
    value_type: "Text"
  },
  {
    name: "Hautkrebsfrüherkennung",
    genders: %w[male female],
    definition: "Ja (ggf. mit Kommentar) / Nein",
    identifier: "text_htkrbsfrhrknnng_d3a6f8",
    value_type: "Text"
  },
  {
    name: "Impfungen über die gesetzlichen Vorgaben hinaus",
    genders: %w[male female],
    definition: "Ja (ggf. mit Kommentar) / Nein",
    identifier: "text_mpfngnbrdgstzlchnvrgbnhns_59b5c0",
    value_type: "Text"
  },
  {
    name: "Übernahme von Homöopathie",
    genders: %w[male female],
    definition: "Ja (ggf. mit Kommentar) / Nein",
    identifier: "text_brnhmvnhmpth_9360b9",
    value_type: "Text"
  },
  {
    name: "Übernahme von Osteopathie",
    genders: %w[male female],
    definition: "Ja (ggf. mit Kommentar) / Nein",
    identifier: "text_brnhmvnstpth_01fa1e",
    value_type: "Text"
  },
  {
    name: "Professionelle Zahnreinigung",
    genders: %w[male female],
    definition: "Ja (ggf. mit Kommentar) / Nein",
    identifier: "text_prfssnllzhnrngng_48c6c8",
    value_type: "Text"
  },
  {
    name: "Spezielle Leistungen bei Burn-Out",
    genders: %w[male female],
    definition: "Ja / Nein ",
    identifier: "boolean_spzlllstngnbbrnt_6bbfc9",
    value_type: "Text"
  }
].freeze

FactoryBot.define do
  factory :category do
    name              { "#{Faker::Commerce.department}-Insurance" }
    sequence(:ident)  { |n| SecureRandom.hex(4) + n.to_s }
    coverage_features { [build(:coverage_feature)] }
    description       { Faker::Hacker.say_something_smart }
    content_page_href { "/someUrl" }
    association :vertical, strategy: :build
    life_aspect { %w[health things retirement].sample }
    enabled_for_advice { false }
    priority { 80 }
    cover_benchmark { 10 }
    metadata {
      {
        tips: ["Für hochwertige Motorräder kann sich auch der Abschluss einer Vollkaskoversicherung lohnen"]
      }
    }

    after(:create) do
      # Master data like categories is cached now for a specific amount of time without touching the database
      # again. Therefor the categories cache has to be manually invalidated whenever something related to
      # categories changes. (See also Domain::MasterData::Categories)
      Domain::MasterData::Categories.invalidate_cache
    end

    trait :advice_enabled do
      enabled_for_advice { true }
    end

    factory :category_gkv do
      name { "Gesetzliche Krankenversicherung" }
      ident { "3659e48a" }
      vertical
      life_aspect { ::Category.life_aspects["health"] }

      coverage_features { GKV_COVERAGE_FEATURES.map { |cf| CoverageFeature.new(cf) } }
    end

    factory :category_kfz do
      name { "KFZ" }
      ident { "d9c5a3fe" }
      life_aspect { ::Category.life_aspects["things"] }
      vertical
    end

    factory :category_hr do
      name { "Hausratversicherung" }
      ident { "e251294f" }
      enabled_for_advice { true }
      life_aspect { ::Category.life_aspects["things"] }
      vertical

      coverage_features {
        HR_COVERAGE_FEATURES.map { |cf| CoverageFeature.new(cf) }
      }
    end

    factory :umbrella_category do
      category_type { Category.category_types[:umbrella] }
    end

    factory :car_umbrella_category do
      category_type { Category.category_types[:umbrella] }
      ident { "58680af3" }
    end

    factory :category_car_insurance do
      name { "KFZ-Versicherung" }
      ident { "15f6b555" }
      enabled_for_advice { true }
    end

    factory :combo_category, traits: %i[combo_category_trait]

    factory :category_pkv do
      name { "Private Krankenversicherung" }
      ident { "4fb3e303" }
      vertical
    end

    factory :category_risk_life do
      name { "Risikolebensversicherung" }
      ident { "e19db46d" }
      enabled_for_advice { true }
      vertical
    end

    factory :category_phv do
      name { "Privathaftpflichtversicherung" }
      ident { "03b12732" }
      enabled_for_advice { true }
      vertical
    end

    factory :category_legal do
      name { "Rechtsschutzversicherung" }
      ident { "5bfa54ce" }
      enabled_for_advice { true }
      vertical
    end

    factory :category_accident_insurace do
      name { "Unfallversicherung" }
      ident { "cf064be0" }
      enabled_for_advice { true }
      vertical
    end

    factory :category_home_insurance do
      name { "Wohngebäudeversicherung" }
      ident { "47a1b441" }
      enabled_for_advice { true }
      vertical
    end

    factory :category_dental do
      name { "Dental" }
      ident { "377e1f7c" }
      enabled_for_advice { true }
      vertical
    end

    factory :category_roadside_assistance do
      name { "Roadside" }
      ident { "d55e03e6" }
      vertical
    end

    factory :category_riester do
      name { "Riester" }
      ident { "68f0b130" }
      vertical
    end

    factory :category_travel_health do
      name { "Travel Health" }
      ident { "875823e3" }
      enabled_for_advice { true }
      vertical
    end

    factory :phv_category_no_coverages do
      id { 10 }
      name { "Privathaftpflichtversicherung" }
      state { "active" }
      vertical
      ident { "03b12732" }
    end

    factory :active_category do
      state { "active" }
    end

    factory :bu_category do
      name { "Berufsunfähigkeitsversicherung" }
      ident { "3d439696" }
      enabled_for_advice { true }
    end

    factory :pa_category do
      name { "Pri­va­te Al­ters­vor­sor­ge" }
      ident { "vorsorgeprivat" }
    end

    factory :high_margin_category do
      name { "Private Krankenversicherung" }
      ident { "4fb3e303" }
    end

    factory :category_retirement do
      name { "Retirement" }
      ident { "c187d55b" }
      life_aspect { ::Category.life_aspects["retirement"] }
    end

    trait :active do
      state { "active" }
    end

    trait :inactive do
      state { "inactive" }
    end

    trait :suhk do
      association :vertical, :suhk
    end

    trait :equity do
      name { "Vermögen" }
      ident { "1fc11bd4" }
      association :vertical, :investment
      life_aspect { "retirement" }
    end

    trait :low_margin do
      margin_level { :low }
    end

    trait :medium_margin do
      margin_level { :medium }
    end

    trait :high_margin do
      margin_level { :high }
    end

    trait :state do
      name { "Gesetzliche Rentenversicherung" }
      ident { "84a5fba0" }
      association :vertical, :state
      life_aspect { "retirement" }
    end

    trait :overall_personal do
      name { "Private Altersvorsorge" }
      ident { "vorsorgeprivat" }
      association :vertical, :overall_personal
      life_aspect { "retirement" }
    end

    trait :overall_corporate do
      name { "Betriebliche Altersvorsorge" }
      ident { "1ded8a0f" }
      association :vertical, :overall_corporate
      life_aspect { "retirement" }
    end

    trait :combo_category_trait do
      combo
    end

    trait :regular do
      category_type { Category.category_types[:regular] }
    end

    trait :umbrella do
      category_type { Category.category_types[:umbrella] }
      included_category_ids { [create(:category).id] }
    end

    trait :combo do
      category_type { Category.category_types[:combo] }
      included_category_ids { [create(:category).id] }
    end

    trait :health do
      life_aspect { Category.life_aspects[:health] }
    end

    trait :retirement do
      life_aspect { Category.life_aspects[:retirement] }
    end

    trait :things do
      life_aspect { Category.life_aspects[:things] }
    end

    factory :retirement_equity_combo_category, traits: %i[combo_category_trait] do
      name { "Retirement Combo Category" }
      ident { "test-combo-category" }
      included_category_ids {
        categories = [create(:category, :equity), create(:category, ident: "test-ident")]
        categories.map(&:id)
      }
    end

    trait :pensionsfonds do
      name { "Pensionsfonds" }
      ident { "ae82f6e4" }
    end

    trait :private_rentenversicherung do
      name { "private-rentenversicherung" }
      ident { "f0a0e78c" }
    end

    trait :kapitallebensversicherung do
      name { "kapitallebensversicherung" }
      ident { "c187d55b" }
    end

    trait :riester_fonds_non_insurance do
      name { "riester_fonds_non_insurance" }
      ident { "1fc11bd2" }
    end

    trait :basis_classic do
      ident { "63cfb93c" }
    end

    trait :basis_fonds do
      ident { "1fc11bd0" }
    end

    trait :direktversicherung_classic do
      ident { "e97a99d7" }
    end

    trait :direktversicherung do
      direktversicherung_classic
    end

    trait :direktzusage do
      ident { "c13f6d0c" }
    end

    trait :category_page do
      customer_description { "Test attributes" }
      benefits { %w[Benefit_1 Benefit_2 Benefit_3] }
      quality_standards_title { "Test title" }
      quality_standards_features { %w[Feature_1 Feature_2 Feature_3] }
      what_happens_if { "What happens if test" }
      priority { 52 }
      cover_benchmark { 76 }
      price_benchmark { "4€" }
      number_companies { "58" }
      number_plans { "347" }
      time_to_offer { "2 Min" }
      post_purchase_satisfaction { "97" }
      selection_guidelines { %w[SelectionGuidelines_1 SelectionGuidelines_2 SelectionGuidelines_3] }
      rating_criteria { %w[RatingCriteria_1 RatingCriteria_2 RatingCriteria_3] }
      clark_warranty { %w[ClarkWarranty_1 ClarkWarranty_2 ClarkWarranty_3] }
      consultant_comment { "Test consultant comment" }
    end
  end
end
