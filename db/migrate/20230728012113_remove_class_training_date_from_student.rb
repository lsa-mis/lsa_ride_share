class RemoveClassTrainingDateFromStudent < ActiveRecord::Migration[7.0]
  def change
    remove_column :students, :class_training_date
  end
end
