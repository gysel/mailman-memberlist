#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'nokogiri'

domain = ARGV[0]
listname = ARGV[1]
password = ARGV[2]

if domain.nil? || listname.nil? || password.nil?
  puts "\nparameter missing! \ncorrect usage: ./memberlist.rb domain.tld listname password"
  exit 2
end


a = Mechanize.new { |agent|
  agent.user_agent_alias = 'Windows Mozilla'
}

a.get("http://#{domain}/cgi-bin/mailman/admin/#{listname}/") do |page|

  # Submit the login form
  page_start = page.form_with(:method => 'POST') do |f|
    f.adminpw  = password
  end.click_button

  # Navigate to the member list
  page_memberlist = page_start.link_with(:text => /Mitglieder-Verwaltung(.*)/).click
  page_memberlist = page_memberlist.link_with(:text => /\[Mitgliederliste\]/).click

  parser = page_memberlist.parser
  parser.css('center tr td').each do |e|
    email = ''
    name = ''

    email_node = e.at_css('a')
    unless email_node.nil?
      email = email_node.content
    end
    name_node = e.at_css('input[type=\'TEXT\']')
    unless name_node.nil?
      name = name_node['value']
    end

    puts name + " <" + email + ">" unless name.empty?
  end

  page_memberlist.link_with(:text => /Logout/).click

end


