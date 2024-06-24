class LinkValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin    
	    uri = URI.parse(value)

	    unless uri.nil? or (uri.kind_of?(URI::HTTP) && !uri.host.nil?)
	      record.errors[attribute] << (options[:message] || "is not a valid link, be sure to include the http://")
	    end	
    rescue Exception => e
    	record.errors[attribute] << (options[:message] || "is not a valid link, be sure to include the http://")
    end
  end
end