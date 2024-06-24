def same_image?(path1, path2)
  return true if path1 == path2
  
  begin
    open(path1) {|image1| 
      open(path2) {|image2|
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

@festival = Festival.find(18)

json_blob = File.read(Rails.root.join("public/guide-data.json"))

data = JSON.parse(json_blob)

data["data"]["detailPage"]["list"].each do |list_item|
  puts list_item['title']
  puts list_item['accordions']['getTotal']

	source_id = list_item['id']

  content = list_item['body']

  list_item['accordions']['list'].each do |a|
    a_content = "<div class='accordionWrap'><h2 class='accordionTitle'>#{a['headline']}</h2>"
    
    a_titles = []

    # Remove weird syntax from the titls 
    # create a registry of the titles
    # add ids to the headers to allow for hash navigation in client
    body = a['body'].gsub(/\-----[A-Za-zçõê\s&\;\/,-]+/){ |sub_accordion|
      sub_accordion.slice! "-----"
      a_titles << {id: sub_accordion.parameterize, header: sub_accordion}
      "<h3 class='accordionSectionTitle' id='#{sub_accordion.parameterize}'>#{sub_accordion}</h3>"
    }

    # Remove inline scripts
    body = body.gsub(/<script.*?>[\s\S]*<\/script>/i, "")

    # Remove /////
    body = body.gsub("/////", "")

    # add index to body text
    text_index = "<ul class='accordion_index'>"
    a_titles.each do |title|
      text_index << "<li><a href='##{title[:id]}'>#{title[:header]}</a></li>"
    end
    text_index << "</ul>"

    a_content = a_content + text_index + body

    a_content << "</div>" #closing .accordionWrap
    content = content + a_content
  end

  @page = @festival.pages.where(source_id: source_id).first_or_initialize
  @page.name = list_item["title"]
  @page.content = content
  
  if @page.image.url === nil or !same_image?(@page.image.url, list_item["images"][0]["httpUrl"])
    @page.remote_image_url = list_item["images"][0]["httpUrl"]
  end

  @page.save!
end