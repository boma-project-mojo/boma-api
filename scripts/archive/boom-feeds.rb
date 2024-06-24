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

# uri = URI('https://boomfestival.org/boom2022/qlapi/auth/')
# params = { :key => ENV['BOOM_API_KEY'] }
# uri.query = URI.encode_www_form(params)

# res = Net::HTTP.get_response(uri)

# cookie = res['set-cookie']

# uri = URI("https://boomfestival.org/boom2022/qlapi/")
# params = { :type => 'news' }
# uri.query = URI.encode_www_form(params)

# http = Net::HTTP.new(uri.host, 443)
# request = Net::HTTP::Get.new(uri.request_uri)
# request['cookie'] = cookie

# request['authority'] = "boomfestival.org"
# request['method'] = "GET"
# request['path'] = "/boom2022/qlapi/?type=news"
# request['scheme'] = "https"
# request['accept'] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
# request['accept-encoding'] = "gzip, deflate, br"
# request['accept-language'] = "en-GB,en-US;q=0.9,en;q=0.8"
# # request['cookie'] = "cp_sessionid=28885405339230985; wires=652161c4e6d68c6a58d54f6e1a15a57b; wires_challenge=6jWEJYwRdRFWv40o2y%2F2vZCIDdmqEk%2F8"
# request['sec-fetch-dest'] = "empty"
# request['sec-fetch-mode'] = "navigate"
# request['sec-fetch-site'] = "same-origin"
# request['sec-gpc'] = 1
# request['upgrade-insecure-requests'] = 1
# request['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.87 Safari/537.36'

# r = http.request(request)
# puts r.inspect

# {
# 	"newsdate"=>"18 February 2022", 
# 	"title"=>"News Wastewater Treatment Plant to #SaveTheDrop", 
# 	"body"=>"", 
# 	"images"=>[
# 		{
# 			"httpUrl"=>"https://boomfestival.org/boom2022/site/assets/files/10450/bacia.png"
# 		}, 
# 		{
# 			"httpUrl"=>"https://boomfestival.org/boom2022/site/assets/files/10450/bacia_contencao_c_fp_6.jpg"
# 		}
# 	], 
# 	"search_keywords"=>"water boomland regeneration"
# }

@organisation = Organisation.find(8)

json_blob = File.read(Rails.root.join("public/news-data.json"))

data = JSON.parse(json_blob)

data["data"]["detailPage"]["list"].each do |list_item|
	source_id = list_item['id']

  @article = @organisation.articles.where(source_id: source_id).first_or_initialize
  @article.standfirst = list_item['summary']
  @article.article_type = 'boma_news_article'
  @article.created_at = DateTime.parse(list_item['newsdate'])
  @article.title = list_item["title"]

  # byebug

  # "/boom2022/site/assets/files/10453/bc21_squarefabiana_kocubey_52_1_1.160x0.jpg"

  # https://cdn.boomfestival.org/assets/files/10453/untitled1.1200x0.gif

  @article.content = list_item["body"].gsub('/boom2022/site/', 'https://cdn.boomfestival.org/')

  @article.content = @article.content.gsub('120x0.gif', '1200x0.gif')
  @article.content = @article.content.gsub('120x0.jpg', '1200x0.jpg')
  @article.content = @article.content.gsub('160x0.gif', '1322x0.gif')
  @article.content = @article.content.gsub('160x0.jpg', '1322x0.jpg')

  if @article.image.url === nil or !same_image?(@article.image.url, list_item["images"][0]["httpUrl"])
    @article.remote_image_url = list_item["images"][0]["httpUrl"]
  end

  @article.save!
end