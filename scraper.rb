require 'nokogiri'
require 'byebug'
require "mechanize"
require 'csv'
require 'dotenv'

Dotenv.load

def scraper
  users = Array.new
  page_num = 1
  total_page =100

  agent = Mechanize.new { |agent|
    agent.user_agent_alias = 'Linux Firefox'
  }

  page = agent.get('https://github.com/login')
  form = page.forms.first
  form.login = ENV["GITHUB_USERNAME"]
  form.password = ENV["GITHUB_PASSWORD"]
  page = agent.submit(form)

  while page_num<= total_page
    page_url = "https://github.com/search?o=desc&q=location%3AIndia&s=followers&type=Users&p=#{page_num}"
    puts "Page #{page_num}"
    page = agent.get(page_url)
    parsed_page = Nokogiri::HTML(page.content)
    profiles = parsed_page.css(".hx_hit-user")
    profiles.each do |profile|
      user = {
        name: profile.css("a.color-text-secondary").text,
        email: profile.css("a.Link--muted").text
      }
    puts user[:name]
    users << user
    end

    if page_num % 10 == 0
      sleep(30)
    end

    page_num +=1
  end

  headers = ["username", "email"]
  CSV.open("github-profiles.csv", "wb", write_headers: true, headers: headers ) do |csv|
    users.each do |hash|
      csv << hash.values
    end
  end
end

scraper
