class Donation
  ATTRIBUTES = [
    {name: :organization},
    {name: :date},
    {name: :amount},
    {name: :is_grant, new_name: :grant?, default: false},
    {name: :is_daf_contribution, new_name: :daf_contribution?, default: false},
    {name: :note, default: nil},
  ]
  def initialize(values)
    ATTRIBUTES.each do |attrs|
      original_name = attrs.fetch(:name)
      new_name = attrs.fetch(:new_name, original_name)
      value = values.fetch(original_name) { attrs.fetch(:default) }
      if new_name == :date
        value = Date.parse(value)
      end
      instance_variable_set(:"@#{original_name}", value)
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
    @organizations ||= File.read("lib/organizations.json")
      .then { |json| JSON.parse(json) }
      .index_by { |org| org.fetch("name") }
  end

  def css_class
    if grant?
      "text-grey-dark"
    end
  end

  def self.load_donations(*)
    File.read("lib/donations.json")
      .then { |json| JSON.parse(json) }
      .map { |donation| Donation.new(donation.symbolize_keys) }
      .sort_by { |donation| [donation.date, donation.organization, donation.amount, donation.note] }
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
