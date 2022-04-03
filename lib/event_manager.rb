require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody'] 
    ).officials
  rescue => exception
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
  # removes all characters except numbers 0-9
  phone_number = phone_number.tr('^0-9', '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    # remove the first character, return that phone number
    phone_number[1..-1]
  else
    'The phone number entered was no good!'
  end
end

def get_reg_hour(reg_date)
  # collect all 'RegDate" fields, count depending on how of day, return list of all counts ordered from most to least popular
  reg_time = reg_date.split[1]
  reg_time.split(':')[0]
end

def get_reg_day_of_week(reg_date)
  # return day of the week based on date
  reg_date = reg_date.split[0].split('/')
  dumbshit = Date.new(reg_date[2].to_i, reg_date[0].to_i, reg_date[1].to_i)
  dumbshit.strftime('%A')
end

puts 'Event Manager Initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_tracker = []
dow_tracker = [] # dow = day of week

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  reg_hour = get_reg_hour(row[:regdate])
  hour_tracker << reg_hour

  dow = get_reg_day_of_week(row[:regdate])
  dow_tracker << dow

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
end

# they didnt ask me to make a seperate function or to embed this WELL, so this is what they get, the data does exist.
# could make a function instead of repeating code but seems more verbose and complex, seems clear these functions do the same thing
hour_count = Hash.new(0)
hour_tracker.each { |hour| hour_count[hour] += 1 }
p hour_count.sort_by { |hour, frequency| frequency }.reverse

day_count = Hash.new(0)
dow_tracker.each { |day| day_count[day] += 1 }
p day_count.sort_by { |day, frequency| frequency }.reverse
