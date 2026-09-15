require "rails_helper"
require "gds_api/test_helpers/calendars"

RSpec.describe WorkingDaysCalculator do
  include GdsApi::TestHelpers::Calendars

  before do
    stub_calendars_has_no_bank_holidays(in_division: "england-and-wales")
  end

  it "cares about england-and-wales holidays by default" do
    calculator = described_class.new(Date.parse("2017-04-27"))

    english_and_welsh_holidays = stub_request(:get, calendars_endpoint(in_division: "england-and-wales"))
      .to_return(status: 200, body: '{"events":[]}')
    scottish_holidays = stub_request(:get, calendars_endpoint(in_division: "scotland"))
      .to_return(status: 200, body: '{"events":[]}')
    northern_irish_holidays = stub_request(:get, calendars_endpoint(in_division: "northern-ireland"))
      .to_return(status: 200, body: '{"events":[]}')
    all_holidays = stub_request(:get, calendars_endpoint)
      .to_return(status: 200, body: '{"events":[]}')

    calculator.public_holidays

    expect(english_and_welsh_holidays).to have_been_requested
    expect(scottish_holidays).not_to have_been_requested
    expect(northern_irish_holidays).not_to have_been_requested
    expect(all_holidays).not_to have_been_requested
  end

  it "cares about the division it is told to care about" do
    calculator = described_class.new(Date.parse("2017-04-27"), in_division: :scotland)

    english_and_welsh_holidays = stub_request(:get, calendars_endpoint(in_division: "england-and-wales"))
      .to_return(status: 200, body: '{"events":[]}')
    scottish_holidays = stub_request(:get, calendars_endpoint(in_division: "scotland"))
      .to_return(status: 200, body: '{"events":[]}')
    northern_irish_holidays = stub_request(:get, calendars_endpoint(in_division: "northern-ireland"))
      .to_return(status: 200, body: '{"events":[]}')
    all_holidays = stub_request(:get, calendars_endpoint)
      .to_return(status: 200, body: '{"events":[]}')

    calculator.public_holidays

    expect(english_and_welsh_holidays).not_to have_been_requested
    expect(scottish_holidays).to have_been_requested
    expect(northern_irish_holidays).not_to have_been_requested
    expect(all_holidays).not_to have_been_requested
  end

  it ".after returns the correct weekday" do
    calculator = described_class.new(Date.parse("2017-04-27"))

    expect(calculator.after(1)).to eq(Date.parse("2017-04-28"))
  end

  it ".after returns the Monday if the next day falls on a Saturday" do
    calculator = described_class.new(Date.parse("2017-04-21"))

    expect(calculator.after(1)).to eq(Date.parse("2017-04-24"))
  end

  it ".after returns the Tuesday if the next day falls on a Sunday" do
    calculator = described_class.new(Date.parse("2017-04-21"))

    expect(calculator.after(2)).to eq(Date.parse("2017-04-25"))
  end

  it ".after accounts for weekends crossed even if they're not the 'next day'" do
    calculator = described_class.new(Date.parse("2017-04-21"))

    expect(calculator.after(3)).to eq(Date.parse("2017-04-26"))
  end

  it ".after returns the Tuesday if the next day is a holiday Monday" do
    stub_calendars_has_a_bank_holiday_on(
      Date.parse("2017-05-01"),
      in_division: "england-and-wales",
    )

    calculator = described_class.new(Date.parse("2017-04-21"))

    expect(calculator.after(6)).to eq(Date.parse("2017-05-02"))
  end

  it ".after returns the Monday if the next day is a holiday Friday" do
    stub_calendars_has_a_bank_holiday_on(
      Date.parse("2016-01-01"),
      in_division: "england-and-wales",
    )

    calculator = described_class.new(Date.parse("2015-12-31"))

    expect(calculator.after(1)).to eq(Date.parse("2016-01-04"))
  end

  it ".after returns the Tuesday if the next day is a holiday on both Friday and Monday" do
    stub_calendars_has_bank_holidays_on(
      [Date.parse("2017-04-14"), Date.parse("2017-04-17")],
      in_division: "england-and-wales",
    )

    calculator = described_class.new(Date.parse("2017-04-13"))

    expect(calculator.after(1)).to eq(Date.parse("2017-04-18"))
  end

  it ".after accounts for holidays crossed even if they're not the 'next day'" do
    stub_calendars_has_a_bank_holiday_on(
      Date.parse("2014-01-01"),
      in_division: "england-and-wales",
    )

    calculator = described_class.new(Date.parse("2013-12-31"))

    expect(calculator.after(2)).to eq(Date.parse("2014-01-03"))
  end
end
