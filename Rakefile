require "bundler/setup"
require "google/api_client"
require "google_drive"
require "active_support/time"
require "dotenv"
require "pry"
require "./fitbit"

Dotenv.load
YEAR = 2018

class Measurement
  attr_reader :date, :weight

  def initialize(date:, weight:)
    @date = date.to_date
    @weight = weight
  end
end

class Series
  attr_reader :measurements

  def initialize(measurements)
    @measurements = measurements.sort_by(&:date)
  end

  def weight_on(date)
    fail "Date outside of range" unless every_day.include?(date)
    fetch(date) do
      assumed_weight_on(date)
    end
  end

  def every_day
    return @every_day if defined?(@every_day)
    begin_date = measurements.first.date
    end_date = measurements.last.date
    @every_day = begin_date..end_date
  end

  def fetch(date)
    measurement = measurements.find { |m| m.date == date }
    return measurement.weight if measurement
    yield date
  end

  private

  def assumed_weight_on(date)
    fail "Weight is actually known on this date" if dates.include?(date)
    fail "Date outside of range" unless every_day.include?(date)
    left_boundary = date
    right_boundary = date
    left_boundary = left_boundary - 1 until dates.include?(left_boundary)
    right_boundary = right_boundary + 1 until dates.include?(right_boundary)
    difference = fetch(right_boundary) - fetch(left_boundary)
    range = left_boundary..right_boundary
    step = difference / (range.to_a.size - 1)
    gap_measurements = range.each_with_index.map do |d, i|
      weight = fetch(left_boundary) + (step * i)
      Measurement.new(date: d, weight: weight.round(1))
    end
    Series.new(gap_measurements).fetch(date)
  end

  def dates
    measurements.map(&:date)
  end
end

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

    measurements = responses.reduce([]) do |memo, response|
      memo + response.map { |i| Measurement.new(date: i["date"], weight: i["weight"]) }
    end

    series = Series.new(measurements)
    File.open("./.measurements.#{args.year}.yaml", "w") { |f| YAML.dump(series, f) }
  end
end

desc "Export data to Google sheets"
task :export, [:year] do |_, args|
  args.with_defaults(year: YEAR)

  communicate "Exporting data to Google sheets" do
    google = GoogleDrive.saved_session("./.google_token.json")
    worksheet = google.spreadsheet_by_title("Average Weight #{args.year.to_i}").worksheet_by_title("fitbit")
    series = YAML.load(File.read(".measurements.#{args.year}.yaml"))

    series.every_day.each_with_index do |date, i|
      worksheet[i + 1, 1] = date.to_s
      worksheet[i + 1, 2] = series.weight_on(date)
    end

    worksheet.save
  end
end

task :play do
  binding.pry
end

desc "Import data from Fitbit and export it to Google sheets"
task :default, [:year] => %i(import export)