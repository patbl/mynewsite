class Donation
  attr_reader :organization, :amount, :note

  ORGANIZATION_URLS = {
    "80,000 Hours" => "http://80000hours.org/",
    "The Humane League" => "http://www.thehumaneleague.com/",
    "Animal Charity Evaluators" => "http://www.animalcharityevaluators.org/",
    "St. Olaf College" => "http://stolaf.edu/",
    "Centre for Effective Altruism" => "https://www.centreforeffectivealtruism.org/",
    ".impact" => "http://dotimpact.im/",
    "Mercy for Animals" => "http://www.mercyforanimals.org/",
    "Effective Altruism Community Fund" => "https://app.effectivealtruism.org/funds/ea-community",
    "Long-Term Future Fund" => "https://app.effectivealtruism.org/funds/far-future",
  }

  def initialize(organization:, date:, amount:, note: nil)
    @organization = organization
    @date = date
    @amount = amount
    @note = note
  end

  def date
    @date.strftime("%-d %B %Y")
  end

  def url
    ORGANIZATION_URLS[organization]
  end

  def self.load_donations
    YAML.load(File.open("lib/donations.yaml")).map { |args|
      Donation.new(args.symbolize_keys)
    }
  end
end
