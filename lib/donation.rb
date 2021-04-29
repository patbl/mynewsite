class Donation
  attr_reader :organization, :date, :amount, :note, :is_grant, :is_daf_contribution

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
    "AIDS/LifeCycle" => "https://www.aidslifecycle.org/",
    "ALLFED" => "http://allfed.info/",
    "Global Catastrophic Risk Institute" => "https://gcrinstitute.org/",
    "Berkeley REACH" => "https://www.berkeleyreach.org/",
    "Berkeley Existential Risk Initiative" => "https://existence.org/",
    "Guarding Against Pandemics" => "https://www.againstpandemics.org/",
    "Rethink Priorities" => "https://www.rethinkpriorities.org/",
    "Donor Lottery" => "https://app.effectivealtruism.org/lotteries",
  }

  def initialize(organization:, date:, amount:, is_grant: false, is_daf_contribution: false, note: nil)
    @organization = organization
    @date = date
    @amount = amount
    @note = note
    @is_grant = is_grant
    @is_daf_contribution = is_daf_contribution
  end

  def amount_donated_by_me
    is_grant ? 0 : amount
  end

  def amount_received_by_charity
    is_daf_contribution ? 0 : amount
  end

  def formatted_date
    date.strftime("%-d %B %Y")
  end

  def url
    ORGANIZATION_URLS[organization]
  end

  def self.load_donations
    YAML.safe_load(File.open("lib/donations.yaml"), [Date]).map { |args|
      Donation.new(**args.symbolize_keys)
    }.sort_by { |donation|
      [donation.date, donation.organization, donation.amount, donation.note]
    }.reverse
  end

  def self.total_donated_by_me
    load_donations.sum(&:amount_donated_by_me)
  end

  def self.total_received_by_charities
    load_donations.sum(&:amount_received_by_charity)
  end
end
