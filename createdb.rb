# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :ascs do
  primary_key :id
  String :asc_name
  String :specialty_type
  String :ownership
  String :state
  String :address
end
DB.create_table! :ratings do
  primary_key :id
  foreign_key :asc_id
  foreign_key :user_id
  Integer :rating
  String :comments, text: true
end

DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
ascs_table = DB.from(:ascs)

ascs_table.insert(asc_name: "UI Health Outpatient Surgery Center", 
                    specialty_type: "Single",
                    ownership: "Hospital-Owned",
                    address: "1801 W Taylor St, Chicago, IL 60612")

ascs_table.insert(asc_name: "Northwestern Medicine Ambulatory Surgery Center", 
                    specialty_type: "Multi",
                    ownership: "Hospital-Owned",
                    address: "710 N Fairbanks Ct, Chicago, IL 60611")

ascs_table.insert(asc_name: "Valley Ambulatory Surgery Center", 
                    specialty_type: "Multi",
                    ownership: "Independent",
                    address: "2475 Dean St, St. Charles, IL 60175")
