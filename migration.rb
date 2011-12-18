require 'sequel'
DB = Sequel.connect ENV['DATABASE_URL']

DB.create_table :resources do 
  primary_key :id
  String :plan
end
