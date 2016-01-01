require "rubygems"
require "bundler/setup"
require "google/api_client"
require "google_drive"
require "active_support/time"
require "dotenv"
require "pry"
require "./fitbit"

Dotenv.load
YEAR = 2015

google = GoogleDrive.saved_session("./.google_token.json")
fitbit = Fitbit.saved_session("./.fitbit_token.json")

worksheet = google.spreadsheet_by_title("Average Weight").worksheet_by_title("fitbit")

responses = (1..12).map do |month|
  date = Date.new(YEAR, month, 1)
  fitbit.get(
    "https://api.fitbit.com/1/user/-/body/log/weight/date/#{date}/#{date.end_of_month}.json",
    headers: { "Accept-Language": "en_US" }
  )
end

measurements = responses.reduce({}) do |memo, response|
  memo.merge(
    JSON.parse(response.body)["weight"].reduce({}) do |m, i|
      m.merge({ i["date"] => i["weight"] })
    end
  )
end

every_day = Date.new(YEAR, 1, 1)..Date.current

last = measurements[measurements.keys.min]
filled = every_day.reduce([]) do |memo, date|
  last = measurements[date.to_s] || last
  memo + [[date.to_s, last]]
end

filled.each_with_index do |(date, weight), i|
  worksheet[i + 1, 1] = date
  worksheet[i + 1, 2] = weight
end

worksheet.save
