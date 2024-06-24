class AddBundleIdToFestival < ActiveRecord::Migration[5.2]
  def change
    add_column :festivals, :bundle_id, :string
  
    Festival.find([1,3,9]).each do |f|
    	f.update! bundle_id: "com.kambe.boma"
    end

    o = Organisation.create! name: "Rover"

    Festival.find([2]).each do |f|
        f.update! organisation: o, bundle_id: "com.rover.boma"
    end

    Festival.find([5,10]).each do |f|
    	f.update! bundle_id: "com.greenbelt.festapp"
    end

    Festival.find([4]).each do |f|
    	f.update! bundle_id: "com.cheltenhamjazz.boma"
    end

    Festival.find([6]).each do |f|
    	f.update! bundle_id: "com.nyege.boma"
    end

    Festival.find([7]).each do |f|
    	f.update! bundle_id: "com.festivalcongress.boma"
    end

    Festival.find([8]).each do |f|
    	f.update! bundle_id: "com.openfest.boma"
    end
  end
end
