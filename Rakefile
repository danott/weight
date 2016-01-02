require "bundler/setup"
require "google/api_client"
require "google_drive"
require "active_support/time"
require "dotenv"
require "./fitbit"

Dotenv.load
YEAR = 2016

def communicate(message)
  print "#{message}..."
  yield
  puts " Done!"
end

desc "Import data from Fitbit"
task :import, [:year] do |_, args|
  fitbit = Fitbit.saved_session("./.fitbit_token.json")
  args.with_defaults(year: YEAR)

  communicate "Importing data from Fitbit" do
    responses = (1..12).map do |month|
      date = Date.new(args.year.to_i, month, 1)
      fitbit.get(
        "https://api.fitbit.com/1/user/-/body/log/weight/date/#{date}/#{date.end_of_month}.json",
        headers: { "Accept-Language": "en_US" }
      )
    end
    responses = responses.map { |response| JSON.parse(response.body)["weight"] }
    measurements = responses.reduce({}) do |memo, response|
      memo.merge response.reduce({}) { |m, i| m.merge i["date"] => i["weight"] }
    end
    File.write("./.measurements.json", JSON.pretty_generate(measurements))
  end
end

desc "Export data to Google sheets"
task :export, [:year] do |_, args|
  args.with_defaults(year: YEAR)

  communicate "Exporting data to Google sheets" do
    google = GoogleDrive.saved_session("./.google_token.json")
    worksheet = google.spreadsheet_by_title("Average Weight #{args.year.to_i}").worksheet_by_title("fitbit")
    measurements = JSON.parse(File.read("./.measurements.json"))

    every_day = Date.parse(measurements.keys.min)..Date.parse(measurements.keys.max)
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
  end
end

desc "Import data from Fitbit and export it to Google sheets"
task :default, [:year] => %i(import export)
