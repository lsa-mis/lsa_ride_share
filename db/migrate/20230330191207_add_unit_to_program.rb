class AddUnitToProgram < ActiveRecord::Migration[7.0]
  def change
    add_reference :programs, :unit, index: true
  end
end
