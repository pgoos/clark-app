# frozen_string_literal: true

shared_examples "400 BadRequest" do
  it "raises BadRequestError" do
    expect { client }
      .to raise_error(
        Carrier::Constituents::Arisecur::Outbound::Errors::BadRequestError,
        "Arisecur - Bad Request!"
      )
  end
end

shared_examples "400 AuthenticationError" do
  it "raises AuthenticationError" do
    expect { client }
      .to raise_error(
        Carrier::Constituents::Arisecur::Outbound::Errors::AuthenticationError,
        error_response.body
      )
  end
end

shared_examples "403 VermittlerBlocked" do
  it "raises VermittlerBlockedError" do
    expect { client }
      .to raise_error(
        Carrier::Constituents::Arisecur::Outbound::Errors::VermittlerBlockedError,
        "Arisecur - Vermittler Blocked!"
      )
  end
end

shared_examples "404 NotFound" do
  it "raises NotFoundError" do
    expect { client }
      .to raise_error(
        Carrier::Constituents::Arisecur::Outbound::Errors::NotFoundError,
        "Arisecur - Not Found!"
      )
  end
end

shared_examples "500 ApiError" do
  it "raises ApiError" do
    expect { client }
      .to raise_error(
        Carrier::Constituents::Arisecur::Outbound::Errors::ApiError,
        "Arisecur - API Error!"
      )
  end
end
