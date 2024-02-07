# frozen_string_literal: true

class Donation
  ATTRIBUTES = [
    :organization,
    :date,
    :amount,
    :is_grant,
    :is_daf_contribution,
    :note,
  ]
  def initialize(values)
    ATTRIBUTES.each do |attr|
      value = values.fetch(attr)
      instance_variable_set(:"@#{attr}", value)
      define_singleton_method(attr) do
        instance_variable_get(:"@#{attr}")
      end
    end
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
    org_data = self.class.organizations[organization] or return
    org_data.fetch(:url)
  end

  def self.organizations
    @organizations ||= donation_data_fetcher
      .organizations
      .index_by { |org| org.fetch(:name) }
  end

  def css_class
    if is_grant
      "text-grey-dark"
    end
  end

  def self.load_donations
    @donations ||= donation_data_fetcher
      .donations
      .map { |donation| Donation.new(donation.symbolize_keys) }
      .sort_by { |donation| [donation.date, donation.organization, donation.amount, donation.note] }
      .reverse
  end

  def self.total_donated_by_me
    load_donations.sum(&:amount_donated_by_me)
  end

  def self.total_received_by_charities
    load_donations.sum(&:amount_received_by_charity)
  end

  def self.donations_by_year
    load_donations
      .group_by { |donation| donation.date.year }
      .sort_by(&:first)
      .reverse
  end

  def self.donation_data_fetcher
    @donation_data_fetcher ||= DonationDataFetcher.new(
      ENV['NOTION_DONATIONS_UPDATER_API_KEY'],
      "6721200455be4b7c820df4a9ce51fd30",
      "738df83195f74d66b466c71519dc5a1b",
    )
  end
end
