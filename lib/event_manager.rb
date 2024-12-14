require 'json'
require 'date'
require 'net/http'
require 'uri'

class EventManager
  attr_reader :attendees, :events, :rsvps

  def initialize
    @attendees = []
    @events = []
    @rsvps = []
  end

  def add_attendee(event, attendee, rsvp_status)
    existing_rsvp = @rsvps.find { |r| r.event == event && r.attendee == attendee }
    if existing_rsvp
      puts "RSVP already exists for #{attendee.name} and #{event.name}."
    else
      @events << event unless @events.include?(event)
      @attendees << attendee unless @attendees.include?(attendee)
      @rsvps << RSVP.new(event, attendee, rsvp_status)
    end
  end

  def list_events
    puts "Events:"
    if @events.empty?
      puts "No events available."
    else
      @events.each { |event| puts "#{event.name} - #{event.date} at #{event.location}" }
    end
  end

  def list_attendees
    puts "Attendees:"
    if @attendees.empty?
      puts "No attendees available."
    else
      @attendees.each { |attendee| puts "#{attendee.name} (#{attendee.email}), ZIP: #{attendee.zip_code}" }
    end
  end

  def find_representatives(attendee)
    if attendee.zip_code.nil? || attendee.zip_code.empty?
      puts "No ZIP code provided for #{attendee.name}."
      return
    end

    uri = URI("https://www.googleapis.com/civicinfo/v2/representatives?key=YOUR_API_KEY&address=#{attendee.zip_code}")
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      puts "Government Representatives for #{attendee.name} (ZIP: #{attendee.zip_code}):"
      data["officials"].each do |official|
        puts "- #{official["name"]}, #{official["party"]}"
      end
    else
      puts "Failed to retrieve representatives for #{attendee.name}."
    end
  end

  def list_representatives_for_all
    @attendees.each { |attendee| find_representatives(attendee) }
  end

  class Event
    attr_accessor :name, :date, :location

    def initialize(name, date, location)
      @name = name
      @date = date
      @location = location
    end
  end

  class Attendee
    attr_accessor :name, :email, :zip_code

    def initialize(name, email, zip_code)
      @name = name
      @email = email
      @zip_code = zip_code
    end
  end

  class RSVP
    attr_accessor :event, :attendee, :status

    def initialize(event, attendee, status)
      @event = event
      @attendee = attendee
      @status = status
    end
  end
end

manager = EventManager.new

event = EventManager::Event.new("Political Engagement Workshop", "2024-12-20", "City Hall")
attendee = EventManager::Attendee.new("Efe", "efe@example.com", "90210")

manager.add_attendee(event, attendee, "confirmed")
manager.list_events
manager.list_attendees
manager.list_representatives_for_all
