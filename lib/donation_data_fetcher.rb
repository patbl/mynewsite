# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

class DonationDataFetcher
  API_VERSION = "2022-06-28"
  BASE_URL = "https://api.notion.com/v1"

  attr_accessor :auth_token, :donations_database_id, :organizations_database_id

  def initialize(auth_token, donations_database_id, organizations_database_id)
    @auth_token = auth_token
    @donations_database_id = donations_database_id
    @organizations_database_id = organizations_database_id
  end

  def organizations
    organizations = fetch_all_items(organizations_database_id)
    organization_infos = organizations.map { |org|
      {
        id: org.dig!("id"),
        name: org.dig!("properties", "organization", "title", 0, "plain_text"),
        url: org.dig!("properties", "URL", "url"),
      }
    }.sort_by { |info| info.fetch(:name) }
  end

  def donations
    donations = fetch_all_items(
      donations_database_id,
      filter: { property: "hidden", checkbox: { equals: false } },
    )
    donation_infos = donations.map { |donation|
      {
        date: donation.dig!("properties", "date", "date", "start").then { |date| Date.parse(date) },
        is_grant: donation.dig!("properties", "grant", "checkbox"),
        is_daf_contribution: donation.dig!("properties", "DAF contribution", "checkbox"),
        amount: donation.dig!("properties", "amount", "number"),
        organization: donation.dig!("properties", "organization name", "rollup", "array", 0, "title", 0, "plain_text"),
        note: donation.dig!("properties", "public note", "rich_text")[0]&.fetch("plain_text"),
      }
    }.sort_by { |info| info.values_at(:date, :organization, :amount) }.
      reverse
  end

  private

  def fetch_all_items(database_id, filter: nil)
    items = []
    start_cursor = nil
    loop do
      response = query_database(database_id, start_cursor, filter)
      items.concat(response["results"])
      start_cursor = response["next_cursor"]
      break unless start_cursor
    end
    items.map { |item| Data[item] }
  end

  def query_database(database_id, start_cursor = nil, filter = nil)
    uri = URI("#{BASE_URL}/databases/#{database_id}/query")
    request = Net::HTTP::Post.new(uri.request_uri, {
      "Authorization" => "Bearer #{@auth_token}",
      "Notion-Version" => API_VERSION,
      "Content-Type" => "application/json",
    }).tap do |req|
      body = { start_cursor: start_cursor, filter: filter }.compact
      req.body = body.to_json
    end
    response = Net::HTTP.new(uri.host, uri.port).then do |http|
      http.use_ssl = true
      http.request(request)
    end
    JSON.parse(response.body)
  end

  Data = Struct.new(:hash) do
    def dig!(*keys)
      keys.reduce(hash) { |h, key| h.fetch(key) }
    end
  end
end
