module DataApiConcern extend ActiveSupport::Concern

  def same_image?(path1, path2)
    return true if path1 == path2
    
    begin
      URI.open(path1) {|image1| 
        URI.open(path2) {|image2|
          return false if image1.size != image2.size
          while (b1 = image1.read(1024)) and (b2 = image2.read(1024))
            return false if b1 != b2
          end
        }
      }
      true
    rescue
      true
    end
  end

  def setup_record_image record, image_url
    if (record.image.url === nil and image_url) or !self.same_image?(record.image.url, image_url)
      record.remote_image_url = image_url
      record.image_last_updated_at = DateTime.now
    end
    return record
  end

  def create_record record, sandbox
    record.data_api_request = true

    save = save_record(record, sandbox)

    if save[:status] === :success
      render json: {
        log: save[:log],
        tag: record
      }, status: :created
    else
      render json: {
        log: save[:log],
        response: record.errors
      }, status: :unprocessable_entity
    end
  end

  def record_human_identifier record
    if record.try(:name)
      hid = record.name
    elsif record.try(:title)
      hid = record.title
    end

    return hid
  end
  
  def save_record record, sandbox=false
    identifier = record_human_identifier(record)

    if sandbox
      if record.changed?
        begin
          if record.valid?
            status = :success
            log = format_log("INFO", "#{record.class.name} #{identifier} will save", record, "WILL SAVE")
          else
            status = :fail
            log = format_log("FATAL", "#{record.class.name} #{identifier} invalid #{record.errors.messages}", record, "FAIL")
          end
        rescue
          status = :fail
          log = format_log("FATAL", "#{record.class.name} #{identifier} invalid #{record.errors.messages}", record, "FAIL")
        end
      else
        status = :success
        log = format_log("INFO", "#{record.class.name} #{identifier} unchanged", record, "UNCHANGED")
      end
    else
      if record.changed?
        begin
          if record.save!
            status = :success
            log = format_log("INFO", "#{record.class.name} #{identifer} saved", record, "SAVE")
          else
            status = :fail
            log = format_log("FATAL", "#{record.class.name} #{identifer} invalid #{record.errors.messages}", record, "FAIL")
          end
        rescue
          status = :fail
          log = format_log("FATAL", "#{record.class.name} #{identifer} invalid #{record.errors.messages}", record, "FAIL")
        end
      else
        status = :success
        log = format_log("INFO", "#{record.class.name} #{identifer} unchanged", record, "UNCHANGED")
      end
    end
    return {status: status, log: log}
  end

  def format_log severity, log, record, status_code
    log = {
      severity: severity,
      log: log,
      boma_id: record.id,
      source_id: record.source_id,
      status_code: status_code
    }

    return log
  end

end