module Validations
  extend ActiveSupport::Concern

  # The WYSWYG editor (CKEditor) in the admin section sometimes returns empty
  # HTML in the place of blank strings.   
  #
  # This triggers validation for attributes that include a single empty HTML 
  # attribute as well as a blank string.  
  def is_blank_or_empty_html html
    unless html.nil? or html == ""
      html = html.strip
      [
        "<p></p>",
        "<P></P>",
        "<p>&nbsp;</p>",
        "<P>&nbsp;</P>",
      ].each do |pattern|
        html.gsub!(pattern, "")
      end
      return html == ""
    else
      return true
    end
  end
end