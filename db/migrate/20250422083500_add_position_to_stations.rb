class AddPositionToStations < ActiveRecord::Migration[7.1]
  def change
    add_column :stations, :position, :integer
    
    # 为现有记录设置默认位置
    Station.order(:id).each.with_index(1) do |station, index|
      station.update_column :position, index
    end
  end
end 