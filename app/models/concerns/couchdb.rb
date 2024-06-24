module Couchdb
  attr_accessor :is_checking_app_validity, :checking_production_validity

  # The name/id for couchdb records is in the format modelNamePrefix_2_modelID
  # this method returns the prefix
  def prefix
    self.class.name.downcase.split(':').last
  end

  # The system can be configured to use one couchdb per Organisation or one per Model
  # configure this using the `data_structure_version` attribute on the Festival model.  
  # for full details see app/models/app_data/festival.rb
  def couchdb_name
    if self.festival
      self.festival.couchdb_name 
    elsif self.organisation
      self.organisation.couchdb_name
    end
  end

  def valid_for_app? checking_production_validity=false
    self.checking_production_validity = checking_production_validity
    self.is_checking_app_validity = true
    is_valid_for_app = valid?
    self.is_checking_app_validity = false
    return is_valid_for_app
  end

  # Returns the couchdb record for this model
  def couch_get
    couchdb = CouchDB.database!(self.couchdb_name) 

    retrieved = false

    while retrieved == false
      begin
        doc = couchdb.get("#{prefix}_2_#{id}") 
        retrieved = true
      rescue Exception => e
        retrieved = false    
      end      
    end
    doc
  end

  # Saves the couchdb record for this model
  def couch_save_doc *args
    couchdb = CouchDB.database!(self.couchdb_name) 

    completed = false
    while completed == false
      begin
        doc = couchdb.save_doc(*args)
        completed = true
        return true
      rescue CouchRest::Conflict => e
        completed = false 
        return false   
      rescue CouchRest::BadRequest => e
        raise e
      rescue Exception => e
        raise e        
        completed = false    
      end      
    end
  end

  # Creates or updates a new couchdb document for this model
  def couch_update_or_create is_callback = false
    prefix = self.class.name.downcase.split(':').last
    doc = couch_get
    unless doc.nil?
      if (preview? or published? or cancelled?) and valid_for_app? and !self.deleted?
        doc['data'] = to_couch_data
        couch_save_doc(doc)
      else
        festival_id = self.festival.id rescue nil

        doc['data'] = {
          aasm_state: :unpublished,
          festival_id: festival_id
        }
        couch_save_doc(doc)
      end
    else
      if (preview? or published? or cancelled?) and valid_for_app?
        doc = couch_save_doc('_id' => "#{prefix}_2_#{id}", 'data' => to_couch_data)
      end
    end
  end

  # Creates or updates a couchdb design doc using the provided document
  def couch_update_or_create_design_doc doc
    couchdb = CouchDB.database!(self.couchdb_name) 

    existing_doc = couchdb.get(doc["_id"]) 

    unless existing_doc.nil?
      existing_doc['data'] = doc[:data] unless doc[:data].nil?
      existing_doc['views'] = doc[:views] unless doc[:views].nil?
      couchdb.save_doc(existing_doc)
    else
      couchdb.save_doc(doc)
    end
  end
end