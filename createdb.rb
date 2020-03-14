# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :ascs do
  primary_key :id
  String :asc_name
  Integer :beds
  String :specialty_type
  String :ownership
  String :state
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

ascs_table.insert(asc_name: "North Central Surgery Center", 
                    beds: 100,
                    specialty_type: "Single",
                    ownership: "Hospital-owned",
                    state: "Illinois")

ascs_table.insert(asc_name: "St. James Outpatient Surgery Center", 
                    beds: 50,
                    specialty_type: "Multi",
                    ownership: "Affiliated",
                    state: "Illinois")

ascs_table.insert(asc_name: "Maple Grove Outpatient Surgery Center", 
                    beds: 40,
                    specialty_type: "Multi",
                    ownership: "Independent",
                    state: "Indiana")
