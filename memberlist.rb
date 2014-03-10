#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'optparse'
require 'ostruct'

options = OpenStruct.new
opts = OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-d", "--domain DOMAINNAME", "Mandatory Domain name") do |p|
    options.domain = p
  end
  opts.on("-l", "--list LISTNAME", "Mandatory List name") do |p|
    options.listname = p
  end
  opts.on("-p", "--password PASSWORD", "Mandatory Password") do |p|
    options.password = p
  end
end

opts.parse!

if options.domain.nil? || options.listname.nil? || options.password.nil?
  puts "Missing argument!\n\n"
  puts opts
  exit 1
end

a = Mechanize.new do |agent|
  agent.user_agent_alias = 'Windows Mozilla'
end

persons = []

a.get("http://#{options.domain}/cgi-bin/mailman/admin/#{options.listname}/") do |page|

  # Submit the login form
  page_start = page.form_with(method: 'POST') do |f|
    f.adminpw  = options.password
  end.click_button

  # Navigate to the member list
  page_memberlist = page_start.link_with(text: /Mitglieder-Verwaltung(.*)/).click
  page_memberlist = page_memberlist.link_with(text: /\[Mitgliederliste\]/).click

  page_memberlist.parser.css('center tr td').each do |e|
    email_node = e.at_css 'a'
    email = email_node.nil? ? '' : email_node.content 

    name_node = e.at_css 'input[type=\'TEXT\']'
    name = name_node.nil? ? '' : name_node['value'] 

    persons << {name: name, email: email} unless email.empty?
  end

  page_memberlist.link_with(text: /Logout/).click

end

persons.sort{ |a,b| a[:name] <=> b[:name] }.each do |person|
  name = person[:name]
  name = "-" if name.empty?
  puts "#{name} <#{person[:email]}>"
end
