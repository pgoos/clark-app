require 'rails_helper'

RSpec.describe CmsMigrator do
  TEST_CASES = [
    {
      old: '{{ cms:helper:greeting_long:"Hallo":"":"unsere Experten haben deine ##vertical## analysiert und im Markt verglichen. Spare jetzt mindestens ##saving## bei einem Wechsel."}}',
      new: '{{ cms:helper greeting_long, "Hallo", "", "unsere Experten haben deine ##vertical## analysiert und im Markt verglichen. Spare jetzt mindestens ##saving## bei einem Wechsel."}}'
    },
    {
      old: '{{ cms:helper:greeting_long:"Hallo":"":"unsere Experten haben deine ##vertical## analysiert und im Markt verglichen. Spare jetzt mindestens ##saving## bei einem Wechsel."}}',
      new: '{{ cms:helper greeting_long, "Hallo", "", "unsere Experten haben deine ##vertical## analysiert und im Markt verglichen. Spare jetzt mindestens ##saving## bei einem Wechsel."}}'
    },
    {
      old: '{{ cms:helper:hero_long:"https://optisure-production.s3.amazonaws.com/comfy/cms/files/files/000/000/866/original/infographic_Was_hinter_den_kulissen_3.jpg":"":"" }}',
      new: '{{ cms:helper hero_long, "https://optisure-production.s3.amazonaws.com/comfy/cms/files/files/000/000/866/original/infographic_Was_hinter_den_kulissen_3.jpg", "", "" }}'
    },
    {
      old: '{{ cms:helper:hero_long:"http://optisure-production.s3.amazonaws.com/comfy/cms/files/files/000/000/406/original/coffeeclark.jpeg":"https://www.clark.de/de?utm_medium=email&utm_source=subscriber&utm_campaign=211015_coffeecampaign_fra&utm_content=hero":"Clark.de" }}',
      new: '{{ cms:helper hero_long, "http://optisure-production.s3.amazonaws.com/comfy/cms/files/files/000/000/406/original/coffeeclark.jpeg", "https://www.clark.de/de?utm_medium=email&utm_source=subscriber&utm_campaign=211015_coffeecampaign_fra&utm_content=hero", "Clark.de" }}'
    },
    {
      old: '{{ cms:helper:text_block_promo_with_headline:"Hallo!":"Danke dür das Beantworten der Quizfrage!":"Hier ist deine Codenummer, die du für einen gratis Kaffee im Sturm und Drang Café einlösen kannst:":"Wir von Clark haben das Ziel Versicherungen einfach und verständlich zu machen. Bist du dir nicht sicher welche Versicherungen du brauchst? Mach kostenfrei den Clark-Check und finde in 3 Minuten heraus wie du dich optimal versichern kannst." }}',
      new: '{{ cms:helper text_block_promo_with_headline, "Hallo!", "Danke dür das Beantworten der Quizfrage!", "Hier ist deine Codenummer, die du für einen gratis Kaffee im Sturm und Drang Café einlösen kannst:", "Wir von Clark haben das Ziel Versicherungen einfach und verständlich zu machen. Bist du dir nicht sicher welche Versicherungen du brauchst? Mach kostenfrei den Clark-Check und finde in 3 Minuten heraus wie du dich optimal versichern kannst." }}',
    },
    {
      old: '{{ cms:helper:button:"Zum Clark-Check":"https://www.clark.de/de/clark-check?utm_medium=email&utm_source=subscriber&utm_campaign=211015_coffeecampaign_fra&utm_content=ctabcheck" }}',
      new: '{{ cms:helper button, "Zum Clark-Check", "https://www.clark.de/de/clark-check?utm_medium=email&utm_source=subscriber&utm_campaign=211015_coffeecampaign_fra&utm_content=ctabcheck" }}',
    },
    {
      old: '{{ cms:page:what.concept1-text }}',
      new: '{{ cms:text what.concept1-text }}',
    },
    {
      old: '{{ cms:page:what.concept1-text:string }}',
      new: '{{ cms:text what.concept1-text }}',
    },
    {
      old: '{{ cms:partial:partner/faq:partner_faq_2 }}',
      new: '{{ cms:partial partner/faq }}',
    },
    {
      old: '{{ cms:helper:mc_button:"Erstinformation ansehen":"erstinformation":false }}',
      new: '{{ cms:helper mc_button, "Erstinformation ansehen", "erstinformation", false }}',
    },
    {
      old: '{{ cms:helper:greeting_short:"Hallo":"":"Clark macht alles was du von einem Offline Makler gewohnt bist, nur komfortabler und jederzeit über die App erreichbar. Mit der Clark App hast du deine Versicherungen jederzeit griffbereit und bekommst - wie gewohnt - von unseren Versicherungsexperten Optimierungvorschläge zu deinen Versicherungen. Unsere App gibt es für iOS und Android." }}',
      new: '{{ cms:helper greeting_short, "Hallo", "", "Clark macht alles was du von einem Offline Makler gewohnt bist, nur komfortabler und jederzeit über die App erreichbar. Mit der Clark App hast du deine Versicherungen jederzeit griffbereit und bekommst - wie gewohnt - von unseren Versicherungsexperten Optimierungvorschläge zu deinen Versicherungen. Unsere App gibt es für iOS und Android." }}',
    },
    {
      old: '{{ cms:helper:text_block_content_with_headline:"Die Clark App im Überblick":"":"" }}',
      new: '{{ cms:helper text_block_content_with_headline, "Die Clark App im Überblick", "", "" }}',
    },
    {
      old: '{{ cms:helper:product_shots_right:"https://101672861266-production-cms-public.s3.amazonaws.com/comfy/cms/files/files/000/000/864/original/unnamed-5.jpg":"":"Deine bestehenden Versicherungen siehst du übersichtlich in deiner Vertragsübersicht" }}',
      new: '{{ cms:helper:product_shots_right:"https://101672861266-production-cms-public.s3.amazonaws.com/comfy/cms/files/files/000/000/864/original/unnamed-5.jpg", "", "Deine bestehenden Versicherungen siehst du übersichtlich in deiner Vertragsübersicht" }}',
    },
    {
      old: '{{ cms:helper:product_shots_left:"https://101672861266-production-cms-public.s3.amazonaws.com/comfy/cms/files/files/000/000/861/original/unnamed-2-1.jpg":"":"Zu jeder deiner Versicherung hast du alle Vertragsdetails immer digital dabei" }}',
      new: '{{ cms:helper product_shots_left, "https://101672861266-production-cms-public.s3.amazonaws.com/comfy/cms/files/files/000/000/861/original/unnamed-2-1.jpg", "", "Zu jeder deiner Versicherung hast du alle Vertragsdetails immer digital dabei" }}',
    },
    {
      old: '{{ cms:helper:text_block_content_with_headline:"Viel Spaß mit der App!":"Solltest du Feedback haben, freuen wir uns über eine E-Mail an service@clark.de und eine Bewertung im App Store.":"" }}',
      new: '{{ cms:helper text_block_content_with_headline, "Viel Spaß mit der App!", "Solltest du Feedback haben, freuen wir uns über eine E-Mail an service@clark.de und eine Bewertung im App Store.", "" }}',
    },
    {
      old: '{{ cms:helper:mc_centered_text:"Gerne helfe ich dir persönlich bei allen deinen Fragen." }}',
      new: '{{ cms:helper mc_centered_text, "Gerne helfe ich dir persönlich bei allen deinen Fragen." }}',
    }
  ]

  TEST_CASES.each do |test_case|
    it 'should calculate the utc offset for a winter date' do
      expect(CmsMigrator.update_comfy_tags(test_case[:old])).to eq test_case[:new]
    end
  end
end






