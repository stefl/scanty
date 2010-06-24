require 'rubygems'
require 'nokogiri'

gem 'haml', ">3"
require 'haml'
require 'haml/html'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'post'

# This allows us to overwrite the primary key, so that you
# can keep the same links for your comments

if ARGV.length == 0
  puts 'I require an XML file name to be passed as an argument.'
  exit 1
end

file = ARGV[0]

doc = Nokogiri::XML(open(file))

def val(item, thing)
  item.children.select{|a| a.name == thing}.first.children.to_s rescue nil
end

n = 0

STDERR.puts Post.all.size

#Post.all.each{|a| a.destroy }

doc.css("channel item").each do |item|
  
  if item
    if val(item, "post_type") == "post" and
       Post.get(val(item, "post_id").to_i).blank? and
       val(item, "status") == "publish" then
     
      STDERR.puts n
      n= n +1
   
    
      post_id = val(item, "post_id").to_i
      title = val(item, "title")
      content = Haml::HTML.new(val(item, "encoded").gsub(/^\<\!\[CDATA\[/,'').gsub(/\]\]\>$/,'').gsub("\n",'<br />')).render
      time = Time.parse val(item, "post_date")
       # # post_parent = item.elements["wp:post_parent"].text.to_i
       tags = []
       # item.elements.each("category") { |cat|
       #   domain = cat.attribute("domain")
       #   if domain and domain.value == "tag"
       #     tags.unshift cat.text
       #   end
       # }
       # tags = tags.map { |t| t.downcase }.sort.uniq
    
       post = Post.new :format=>"haml", :id => post_id, :title => title, :tags => tags.join(' '), :body => content, :published_at => time, :slug => Post.make_slug(title)
       if post.save
         puts "Saved post: id ##{post.id} #{title}"
       else
         puts "ERROR! could not save post #{title}"
         exit
       end
    end
  end
end

STDERR.puts Post.all.inspect
