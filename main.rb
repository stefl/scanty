require 'rubygems'
require 'yaml'
require 'sinatra'
require 'haml'
require 'tilt'
require 'dm-pager'

CONFIG = File.join( File.dirname(__FILE__), 'config.yml' )

configure do
  require 'ostruct'
  Blog = OpenStruct.new(
  	unless !File.file?(CONFIG)
      YAML.load_file(CONFIG)
    else
    {
      :admin_cookie_key => ENV['admin_cookie_key'],
      :admin_cookie_value => ENV['admin_cookie_value'],
      :admin_password => ENV['admin_password'],
      :author => ENV['author'],
      :title => ENV['title'],
      :url_base => ENV['url_base'],
      :disqus_shortname => ENV['disqus_shortname']
    }
    
    end
  )
end

error do
	e = request.env['sinatra.error']
	puts e.to_s
	puts e.backtrace.join("\n")
	"Application error"
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'post'

helpers do
	def admin?
		request.cookies[Blog.admin_cookie_key] == Blog.admin_cookie_value
	end

	def auth
	  throw(:halt, [401, "Not authorized\n"]) unless admin?
	end
	
	def not_found
	  throw(:halt, [404, "Page not found\n"])
  end
end

layout 'layout'

### Public

get '/' do
	posts = Post.all(:order=>[:published_at.desc], :limit=>10)
	haml :index, :locals => { :posts => posts }
end

get '/:year/:month/:slug/' do
	post = Post.first(:slug => params[:slug])
	not_found unless post
	@title = post.title
	haml :post, :locals => { :post => post }
end

get '/:year/:month/:slug' do
	redirect "/past/#{params[:year]}/#{params[:month]}/#{params[:day]}/#{params[:slug]}/", 301
end

get '/archive' do
	posts = Post.all(:order=>[:published_at.desc])
	@title = "Archive"
	haml :archive, :locals => { :posts => posts }
end

get '/tag/:tag' do
	tag = params[:tag]
	posts = Post.all(:tags.like => ("%#{tag}%"), :order=>[:published_at.desc], :limit=>30)
	@title = "Posts tagged #{tag}"
	haml :tagged, :locals => { :posts => posts, :tag => tag }
end

get '/feed' do
	@posts = Post.all(:order=>[:published_at.desc], :limit=>20)
	content_type 'application/atom+xml', :charset => 'utf-8'
	builder :feed
end

get '/rss' do
	redirect '/feed', 301
end

### Admin

get '/auth' do
	haml :auth
end

post '/auth' do
	response.set_cookie(Blog.admin_cookie_key.to_s, Blog.admin_cookie_value) if params[:password] == Blog.admin_password
	redirect '/'
end

get '/posts/new' do
	auth
	haml :new, :locals => { :post => Post.new, :url => '/posts' }
end

post '/posts' do
	auth
	post = Post.new :title => params[:title], :tags => params[:tags], :body => params[:body], :published_at => Time.now, :slug => Post.make_slug(params[:title])
	post.save
	redirect post.url
end

get '/:year/:month/:slug/edit' do
	auth
	post = Post.first(:slug => params[:slug])
	not_found unless post
	haml :edit, :locals => { :post => post, :url => post.url }
end

get '/:year/:month/:slug/delete' do
	auth
	post = Post.first(:slug => params[:slug])
	not_found unless post
	post.destroy
	redirect '/'
end

post '/:year/:month/:slug/' do
	auth
	post = Post.first(:slug => params[:slug])
	not_found unless post
	post.title = params[:title]
	post.tags = params[:tags]
	post.body = params[:body]
	post.save
	redirect post.url
end
