Given("a subcompany with {string} configured as broker pool") do |pool_name|
  # TODO: implement related method in APIFacade::AutomationHelpersAPIAdapter
  post('subcompany', subcompany: { attributes: { pool: pool_name } })
end

Given("there is a commission rate for {string} with {int}% as deduction reserve sales and {int}% as deduction fidelity sales") do |string, deduction_reserve, deduction_fidelity|
  pending # Write code here that turns the phrase above into concrete actions
end

When("admin accesses product edition view") do
  pending # Write code here that turns the phrase above into concrete actions
end

Then("admin sees the deductions") do
  pending # Write code here that turns the phrase above into concrete actions
end

Given("admin accesses product edition view") do
  pending # Write code here that turns the phrase above into concrete actions
end

Given("admin sets {int} as aquisition value") do |int|
  pending # Write code here that turns the phrase above into concrete actions
end

Then("admin sees {int} for cancellation reserve") do |int|
  pending # Write code here that turns the phrase above into concrete actions
end

Then("admin sees {int} for trust damage liability") do |int|
  pending # Write code here that turns the phrase above into concrete actions
end

Then("admin sees {int} for net payout amount") do |int|
  pending # Write code here that turns the phrase above into concrete actions
end

Given("a product with {string} configured as sales channel") do |string|
  pending # Write code here that turns the phrase above into concrete actions
end

