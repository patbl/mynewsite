class Donation
  ORGANIZATION_URLS = {
    "80,000 Hours" => "http://80000hours.org/",
    "The Humane League" => "http://www.thehumaneleague.com/",
    "Animal Charity Evaluators" => "http://www.animalcharityevaluators.org/",
    "St. Olaf College" => "http://stolaf.edu/",
    "Centre for Effective Altruism" => "https://www.centreforeffectivealtruism.org/",
    ".impact (now Rethink Charity)" => "https://www.rethinkprojects.org/",
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

  ATTRIBUTES = [
    {name: :organization},
    {name: :date},
    {name: :amount},
    {name: :is_grant, new_name: :grant?, default: false},
    {name: :is_daf_contribution, new_name: :daf_contribution?, default: false},
    {name: :note, default: nil},
    {name: :ineffectual, new_name: :ineffectual?, default: false},
    {name: :hidden, new_name: :hidden?, default: false},
  ]
  def initialize(values)
    ATTRIBUTES.each do |attrs|
      original_name = attrs.fetch(:name)
      new_name = attrs.fetch(:new_name, original_name)
      instance_variable_set(:"@#{original_name}", values.fetch(original_name) { attrs.fetch(:default) })
      define_singleton_method(new_name) do
        instance_variable_get(:"@#{original_name}")
      end
    end
  end

  def amount_donated_by_me
    grant? ? 0 : amount
  end

  def amount_received_by_charity
    daf_contribution? ? 0 : amount
  end

  def formatted_date
    date.strftime("%-d %B %Y")
  end

  def url
    case organization
    when "EA Giving Group donor-advised fund"
      return "/misc/other/donations/ea_giving_group.html"
    end

    return unless (org_data = organizations[organization])

    org_data.fetch("url")
  end

  def organizations
    @organizations ||= YAML.safe_load(File.open("lib/organizations.yaml"))
  end

  def ineffectual_amount_donated
    ineffectual? ? amount_donated_by_me : 0
  end

  def possibly_effectual_amount_donated
    ineffectual? ? 0 : amount_donated_by_me
  end

  def css_class
    if ineffectual?
      "text-red-500"
    elsif grant?
      "text-grey-dark"
    end
  end

  def self.load_donations(show_hidden:)
    YAML.safe_load_file("lib/donations.yaml", permitted_classes: [Date]).map { |args|
      Donation.new(args.symbolize_keys)
    }
    .select { |donation| show_hidden || !donation.hidden? }
    .sort_by { |donation|
      [donation.date, donation.organization, donation.amount, donation.note]
    }
    .reverse
  end

  def self.total_donated_by_me(show_hidden:)
    load_donations(show_hidden: show_hidden).sum(&:amount_donated_by_me)
  end

  def self.total_received_by_charities(show_hidden:)
    load_donations(show_hidden: show_hidden).sum(&:amount_received_by_charity)
  end

  def self.donations_by_year(show_hidden:)
    load_donations(show_hidden: show_hidden)
      .group_by { |donation| donation.date.year }
      .sort_by(&:first)
      .reverse
  end
end
