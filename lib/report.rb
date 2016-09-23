require 'sqlite3'
require 'mail'

outfile = "/srv/websites/field-audit/lib/export.csv"
output = File.new(outfile,"w")

# connect to database
db = SQLite3::Database.open "../db/field-audit.sqlite3"

# select all
output.puts "Supplier,Community,Lot,Task,Builder,Posted On,House Ready for Task?,Task Completed on Time,House Clean?,Quality,Vendor Started Task?"

db.execute 'SELECT * FROM audits' do |row|
  output.print "\"#{row[1]}\""  # supplier
  output.print ","
  output.print row[2]  # community
  output.print ","
  output.print row[3]  # Lot
  output.print ","
  output.print row[4]  # Task
  output.print ","
  output.print row[5]  # Builder
  output.print ","
  output.print "\"#{Date.parse(row[6]).strftime("%b %-d, %Y")}\""  # Posted
  output.print ","
  output.print row[7]  # Ready
  output.print ","
  output.print row[8]  # ontime
  output.print ","
  output.print row[9]  # clean
  output.print ","
  output.print row[10] # quality
  output.print ","
  output.print row[11] # started

  output.puts ""
end

# put into CSV file
output.close

# email CSV file
mail = Mail.new do
  from           "chris@e-signaturehomes.com"
  to             "chris@e-signaturehomes.com"
  subject        "Field Audit Export"
  add_file       outfile

  text_part do
    body         "Change your email to accept HTML messages. Chris\n\n"
  end

  html_part do
    content_type "text/html; charset=UTF-8"
    body         "Field Audit Export Attached."
  end
end

mail.deliver!

# exit

