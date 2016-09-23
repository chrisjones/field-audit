require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'logger'
require 'sqlite3'
require 'date'
require 'active_support/core_ext/date/calculations'
require 'carrierwave'
require 'carrierwave/orm/activerecord'
require 'digest/md5'
require './lib/constants.rb'
require './lib/helpers.rb'
require 'mail'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  ((username == 'cryan' and password == 'xxx') or
   (username == 'dbethers' and password == 'xxx'))
end

::Logger.class_eval { alias :write :'<<' }
access_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log',"#{settings.environment}_access.log")
access_logger = ::Logger.new(access_log)
error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'log',"#{settings.environment}_error.log"),"a+")
error_logger.sync = true

set :database, { adapter: "sqlite3", database: "db/field-audit.sqlite3" }
#set :method_override, true

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  process :resize_to_fit => [360,360]
  storage :file

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    if super.present?
      @name ||= Digest::MD5.hexdigest(File.dirname(current_path))
      "#{@name}.#{file.extension.downcase}"
    end
  end
end

class Audit < ActiveRecord::Base
  has_many :images, :dependent => :destroy
  accepts_nested_attributes_for :images, :allow_destroy => true
end

class Image < ActiveRecord::Base
  belongs_to :audit

  attr_accessor :file

  mount_uploader :file, ImageUploader
end

configure do
  use ::Rack::CommonLogger, access_logger
end

before {
  env["rack.errors"] =  error_logger
}



get "/new" do
  @posted = DateTime.now
  @city = params[:city]
  @builders = load_builders(@city)
  @communities = load_communitys(@city)
  @suppliers = load_suppliers(@city)
  erb :new
end

post "/new" do
  audit = Audit.new
  audit.vendor = params[:vendor]
  audit.location = params[:city]
  audit.community = params[:community]
  audit.lot = params[:lot]
  audit.builder = params[:builder]
  audit.task = params[:task]
  audit.posted = params[:posted]

  audit.revised_start = Date.strptime(params[:rev_start], "%m/%d/%Y") if !params[:rev_start].empty?
  audit.revised_end = Date.strptime(params[:rev_end], "%m/%d/%Y") if !params[:rev_end].empty?
  audit.actual_start = Date.strptime(params[:act_start], "%m/%d/%Y") if !params[:act_start].empty?
  audit.actual_end = Date.strptime(params[:act_end], "%m/%d/%Y") if !params[:act_end].empty?

  audit.ready = params[:ready]
  audit.completed = params[:ontime] 
  audit.clean = params[:clean] 
  audit.quality = params[:quality] 
  audit.started = params[:started]

  audit.note = params[:note]

  unless params[:images].nil?
    params[:images].each do |i|
      upload = audit.images.new
      upload.file = i
      upload.save
    end
  end

  audit.save

  flash[:notice] = "Audit successfully created."
  redirect "/#{audit.id}"
end

get "/audits" do
  @audits = Audit.order(posted: :desc)
  erb :audits
end

get '/' do
  erb :locations
end

get '/report' do
  two_months_ago = Date.today - 2.months

  query = "SELECT audits.posted, COUNT(*) as day_count FROM audits WHERE audits.posted >= date(#{two_months_ago.strftime("%Y-%m-%d")}) group by DATE(audits.posted)"
  audits = Audit.find_by_sql(query)
 
  timeperiod = Hash.new
  ((two_months_ago)..Date.today).map { |d| timeperiod[d.to_s] = 0 }
  audits.each do |a| 
    if a['posted'] >= two_months_ago
      timeperiod[a['posted'].strftime("%Y-%m-%d")] = a['day_count'] 
    end
  end

  @days = Array.new
  @count = Array.new

  timeperiod.each do |k,v|
    @days << k
    @count << v
  end

  erb :report
end

get "/favicon.ico" do
end

get "/:id" do
  @audit = Audit.find(params[:id])
  erb :audit
end

post "/:id/delete" do 
  @audit = Audit.find(params[:id])
  @audit.destroy
  flash[:notice] = "Audit deleted."
  redirect '/audits'
end

post "/:id/email" do
  audit = Audit.find(params[:id])

  email_body = ""
  email_body << "<html><body>"
  email_body << "<center>"
  email_body << "<img src=\"http://field-audit.e-signaturehomes.com/Sighomes-Logo-350.jpg\" />"
  email_body << "<h1>Field Audit</h1>"
  email_body << "<table cellpadding=\"5\">"
  email_body << "<tr>"
  email_body << "  <td><b>Supplier:</b> #{audit.vendor}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>Builder:</b> #{audit.builder}</td>"
  email_body << "</tr>"
  email_body << "<tr>"
  email_body << "  <td><b>Community:</b> #{audit.community}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>Date:</b> #{audit.posted.in_time_zone("America/Chicago").strftime("%A, %b %-d, %Y")}</td>"
  email_body << "</tr>"
  email_body << "<tr>"
  email_body << "  <td><b>Lot:</b> #{audit.lot}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>Time:</b> #{audit.posted.in_time_zone("America/Chicago").strftime("%l:%M %p")}</td>"
  email_body << "</tr>"
  email_body << "<tr>"
  email_body << "  <td><b>Task:</b> #{audit.task}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "</tr>"
  email_body << "<tr>"
  email_body << "  <td><b>Hard5 Start:</b> #{audit.revised_start.strftime("%b %-d, %Y") if !audit.revised_start.nil?}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>Actual Start:</b> #{audit.actual_start.strftime("%b %-d, %Y") if !audit.actual_start.nil?}</td>"
  email_body << "</tr>"
  email_body << "<tr>"
  email_body << "  <td><b>Hard5 End:</b> #{audit.revised_end.strftime("%b %-d, %Y") if !audit.revised_end.nil?}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>Actual End:</b> #{audit.actual_end.strftime("%b %-d, %Y") if !audit.actual_end.nil?}</td>"
  email_body << "</tr>"
  email_body << "</table>"

  email_body << "<br />"

  email_body << "<table cellspacing=\"5\">"
  email_body << "<tr>"
  email_body << "  <td><b>Task Completed on Time?</b></td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>House Clean?</b></td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>Quality</b></td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td><b>Vendor Started Task?</b></td>"
  email_body << "</tr>"
  email_body << "<tr>"
  email_body << "  <td>#{audit.completed.empty? ? "Skipped" : audit.completed}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td>#{audit.clean.empty? ? "Skipped" : audit.clean}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td>#{audit.quality.empty? ? "Skipped" : audit.quality}</td>"
  email_body << "  <td>&nbsp</td>"
  email_body << "  <td>#{audit.started.empty? ? "Skipped" : audit.started}</td>"
  email_body << "</tr>"
  email_body << "</table>"

  email_body << "<p> </p>"

  email_body << "<p><b>Notes:</b><br />"
  email_body << "#{audit.note}"
  email_body << "</p>"

  email_body << "<p> </p>"

  email_body << "<table><tr>"
  count = 0
  audit.images.each do |image|
  	if (count % 2 == 0)
  		email_body << "</tr><tr>"
  	end
    email_body << "\n<td><img src=\"http://field-audit.e-signaturehomes.com#{image.file}\" /></td>"
    count =+ 1
  end
  email_body << "</tr></table>"

  email_body << "</center>"
  email_body << "</body></html>"

  case audit.location
  when "birmingham" then to_field = "field-audit@e-signaturehomes.com"
  when "nashville" then to_field = "tbelcher@e-signaturehomes.com,csmith@e-signaturehomes.com,jhill@e-signaturehomes.com,BNA-Builders@e-signaturehomes.com"
  else
    to_field = "chris@e-signaturehomes.com"
  end

  mail = Mail.new do
    from          "chris@e-signaturehomes.com"
    to            to_field
#    to            "chris@e-signaturehomes.com"
    bcc           "chris@e-signaturehomes.com"
    subject       "Audit: #{audit.community} #{audit.lot} #{audit.task}"

    text_part do
      body        "Change your email to accept HTML messages. Chris\n\n"
    end

    html_part do
      content_type "text/html; charset=UTF-8"
      body        email_body
    end
  end

  if mail.deliver!
    flash[:notice] = "Email sent successfully."
    redirect '/audits'
  end
end
