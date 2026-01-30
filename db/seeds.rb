# This file allows the Rails app to load every .rb file within the /db/seeds directory.
#
# The other files should contain the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
Dir[File.join(File.dirname(__FILE__), "seeds", "*.rb")].each do |f|
  load f
end