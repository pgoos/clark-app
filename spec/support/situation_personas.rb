module SituationPersonas
  def single_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(true)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(false)
    allow(persona).to receive(:official?).and_return(false)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def single_situation_claim
    single_situation(has_single_claim: true)
  end

  def single_official_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(true)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(false)
    allow(persona).to receive(:official?).and_return(true)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def single_official_situation_claim
    single_official_situation(has_single_claim: true)
  end

  def single_deductible_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(true)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(true)
    allow(persona).to receive(:official?).and_return(false)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def single_deductible_situation_claim
    single_deductible_situation(has_single_claim: true)
  end

  def single_official_deductible_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(true)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(true)
    allow(persona).to receive(:official?).and_return(true)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def single_official_deductible_situation_claim
    single_official_deductible_situation(has_single_claim: true)
  end

  def duo_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(true)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(false)
    allow(persona).to receive(:official?).and_return(false)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def duo_situation_claim
    duo_situation(has_single_claim: true)
  end

  def duo_official_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(true)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(false)
    allow(persona).to receive(:official?).and_return(true)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def duo_official_situation_claim
    duo_official_situation(has_single_claim: true)
  end

  def duo_deductible_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(true)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(true)
    allow(persona).to receive(:official?).and_return(false)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def duo_deductible_situation_claim
    duo_deductible_situation(has_single_claim: true)
  end

  def duo_official_deductible_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(true)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(false)
    allow(persona).to receive(:deductible?).and_return(true)
    allow(persona).to receive(:official?).and_return(true)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def duo_official_deductible_situation_claim
    duo_official_deductible_situation(has_single_claim: true)
  end

  def family_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(true)
    allow(persona).to receive(:deductible?).and_return(false)
    allow(persona).to receive(:official?).and_return(false)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def family_situation_claim
    family_situation(has_single_claim: true)
  end

  def family_official_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(true)
    allow(persona).to receive(:deductible?).and_return(false)
    allow(persona).to receive(:official?).and_return(true)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def family_official_situation_claim
    family_official_situation(has_single_claim: true)
  end

  def family_deductible_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(true)
    allow(persona).to receive(:deductible?).and_return(true)
    allow(persona).to receive(:official?).and_return(false)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def family_deductible_situation_claim
    family_deductible_situation(has_single_claim: true)
  end

  def family_official_deductible_situation(has_single_claim: false)
    persona = RSpec::Mocks::Double.new
    allow(persona).to receive(:couple?).and_return(false)
    allow(persona).to receive(:single?).and_return(false)
    allow(persona).to receive(:family?).and_return(true)
    allow(persona).to receive(:deductible?).and_return(true)
    allow(persona).to receive(:official?).and_return(true)
    allow(persona).to receive(:has_single_claim?).and_return(has_single_claim)

    persona
  end

  def family_official_deductible_situation_claim
    family_official_deductible_situation(has_single_claim: true)
  end
end
