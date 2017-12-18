class Donation
  attr_reader :organization, :amount, :note, :is_grant

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
    "MIRI" => "https://intelligence.org/",
  }

  def initialize(organization:, date:, amount:, is_grant: false, note: nil)
    @organization = organization
    @date = date
    @amount = amount
    @note = note
    @is_grant = is_grant
  end

  def contribution_amount
    is_grant ? 0 : amount
  end

  def date
    @date.strftime("%-d %B %Y")
  end

  def url
    ORGANIZATION_URLS[organization]
  end

  def self.load_donations
    YAML.safe_load(File.open("lib/donations.yaml"), [Date]).map { |args|
      Donation.new(args.symbolize_keys)
    }
  end

  def self.total
    load_donations.map(&:contribution_amount).inject(0, :+)
  end
end
