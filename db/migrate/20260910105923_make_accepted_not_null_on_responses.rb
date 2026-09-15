class MakeAcceptedNotNullOnResponses < ActiveRecord::Migration[8.1]
  def change
    change_column_null :responses, :accepted, false
  end
end
