const { Client } = require("@notionhq/client")
const fs = require('fs');

const notion = new Client({
  auth: process.env.NOTION_DONATIONS_UPDATER_API_KEY,
});

const donationsDatabaseId = "6721200455be4b7c820df4a9ce51fd30";
const organizationsDatabaseId = "738df83195f74d66b466c71519dc5a1b";

async function queryDatabase() {
  let organizations = [];
  let organizationsStartCursor;
  do {
    const response = await notion.databases.query({
      database_id: organizationsDatabaseId,
    });
    organizations = organizations.concat(response.results);
    organizationsStartCursor = response.next_cursor;
  } while (organizationsStartCursor);
  const organizationMap = {}
  const organizationInfos = []
  organizations.forEach(org => {
    organizationMap[org.id] = org.properties.organization.title[0].plain_text
    organizationInfos.push({
      id: org.id,
      name: org.properties.organization.title[0].plain_text,
      url: org.properties.URL?.url,
    })
  });
  organizationInfos.sort((a, b) => a.name.localeCompare(b.name));
  const orgJson = JSON.stringify(organizationInfos, null, 2);
  fs.writeFileSync('organizations.json', orgJson, 'utf8');

  let donations = []
  let startCursor;
  do {
    const response = await notion.databases.query({
      database_id: donationsDatabaseId,
      start_cursor: startCursor,
      filter: {
        property: "hidden",
        checkbox: {
          equals: false,
        },
      },
    });
    donations = donations.concat(response.results);
    startCursor = response.next_cursor;
  } while (startCursor);

  const donationInfos = donations.map(donation => {
    donation = donation.properties
    const date = donation.date.date.start
    const isGrant = donation.grant.checkbox
    const isDafContribution = donation['DAF contribution'].checkbox
    const amount = donation.amount.number
    const organizationName = donation['organization name'].rollup.array[0].title[0].plain_text
    const note = donation['public note'].rich_text[0]?.plain_text
    return {
      date: date,
      is_grant: isGrant,
      is_daf_contribution: isDafContribution,
      amount: amount,
      organization: organizationName,
      note
    }
  });
  donationInfos.sort((a, b) => {
    if (a.date !== b.date) {
      return new Date(b.date) - new Date(a.date);
    }
    if (a.organization !== b.organization) {
      return a.organization.localeCompare(b.organization);
    }
    return a.amount - b.amount;
  });
  try {
    const donationInfosYaml = JSON.stringify(donationInfos, null, 2);
    fs.writeFileSync('donations.json', donationInfosYaml, 'utf8');
  } catch (e) {
    console.log(e);
  }
}

queryDatabase().catch(console.error);
