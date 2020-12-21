# frozen_string_literal: true

RSpec.shared_examples "paginated entities" do |resource, assignment_name|
  context "when there are entities not enough for 2 pages" do
    it "assignes #{assignment_name} with all entities" do
      subject.entities_per_page = entities.count
      Timecop.freeze(Time.zone.today + 7) do
        get resource, params: {locale: :de}
        expect(response.status).to eq(200)
        expect(assigns(assignment_name)).to match_array(entities)
      end
    end
  end

  context "when there are entities enough for 2 pages" do
    it "assignes #{assignment_name} on the first page" do
      subject.entities_per_page = entities.count - 1
      Timecop.freeze(Time.zone.today + 7) do
        get resource, params: {locale: :de, page: 1}
        expect(response.status).to eq(200)
        expect(assigns(assignment_name).size).to eq(entities.count - 1)
      end
    end

    it "assignes #{assignment_name} on the second page" do
      subject.entities_per_page = entities.count - 1
      Timecop.freeze(Time.zone.today + 7) do
        get resource, params: {locale: :de, page: 2}
        expect(response.status).to eq(200)
        expect(assigns(assignment_name).size).to eq(1)
      end
    end
  end
end
