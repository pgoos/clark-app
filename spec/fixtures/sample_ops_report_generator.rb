# frozen_string_literal: true

class SampleOpsReportGenerator
  def generate_csv
    <<-EOS
      name, email, location
      Marshall Mathers, slimshady@drdre.com, 8 Mile Detroit
    EOS
  end
end
