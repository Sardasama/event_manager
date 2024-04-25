require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

template_letter = File.read('form_letter.html')

puts 'Event Manager Initialized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)

  clean_phone = phone.delete('-').delete(' ').delete('(').delete(')').delete('.')

  case clean_phone.length
  when 10
    clean_phone
  when 11 && clean_phone[0] == 1
      clean_phone[1, 10]
  else
    "bad number"
  end
end  


def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thankyou_letter(letter, id)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts letter
  end
end

# main program
if !File.exist? 'event_attendees.csv'
  abort("File doesn't exist!")
else
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )

  erb_template = ERB.new template_letter
  time_arr = Array.new
  day_of_w_arr = Array.new

  contents.each do |row|
    id = row[0]

    reg_time = Time.strptime(row[1], "%m/%d/%Y %k:%M")
    time_arr << reg_time.strftime("%k")

    day_of_w_arr << reg_time.wday

    #name = row[:first_name]

    #zipcode = clean_zipcode(row[:zipcode])

    #phone = clean_phone_number(row[:homephone])

    #puts "#{id} : #{name} registered at #{} with phone #{phone}"

    #legislators = legislators_by_zipcode(zipcode)

    #form_letter = erb_template.result(binding)

    #save_thankyou_letter(form_letter, id)
  end
  hash = time_arr.group_by {|h| h}
  hash.update(hash) {|_, h| h.count}
  hash = hash.sort_by { |k, v| v}.reverse!
  hash.each { |hour, nb| puts "#{nb} persons registered at #{hour}."}

  puts 
  hashd = day_of_w_arr.group_by {|d| d}
  hashd.update(hashd) {|_, d| d.count}
  hashd = hashd.sort_by { |k, v| v}.reverse!
  hashd.each do |day, nb| 
    case day
    when 0
        day_of_week = "Sunday"
    when 1
        day_of_week = "Monday"
    when 2
        day_of_week = "Tuesday"
    when 3
        day_of_week = "Wednesday"
    when 4
        day_of_week = "Thursday"       
    when 5
        day_of_week = "Friday"
    when 6
        day_of_week = "Saturday"
    end

    puts "#{nb} persons registered on #{day_of_week}."
  end
end


