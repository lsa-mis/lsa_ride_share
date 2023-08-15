class AddUnitTiSite < ActiveRecord::Migration[7.0]
  def change
    add_reference :sites, :unit, index: true
  end
end
