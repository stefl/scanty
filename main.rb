require 'rubygems'
require 'yaml'
require 'sinatra'
require 'sinatra/sequel'

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
      :url_base => ENV['url_base']
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
	posts = Post.reverse_order(:created_at).limit(10)
	erb :index, :locals => { :posts => posts }, :layout => false
end

get '/past/:year/:month/:day/:slug/' do
	post = Post.filter(:slug => params[:slug]).first
	not_found unless post
	@title = post.title
	erb :post, :locals => { :post => post }
end

get '/past/:year/:month/:day/:slug' do
	redirect "/past/#{params[:year]}/#{params[:month]}/#{params[:day]}/#{params[:slug]}/", 301
end

get '/past' do
	posts = Post.reverse_order(:created_at)
	@title = "Archive"
	erb :archive, :locals => { :posts => posts }
end

get '/past/tags/:tag' do
	tag = params[:tag]
	posts = Post.filter(:tags.like("%#{tag}%")).reverse_order(:created_at).limit(30)
	@title = "Posts tagged #{tag}"
	erb :tagged, :locals => { :posts => posts, :tag => tag }
end

get '/feed' do
	@posts = Post.reverse_order(:created_at).limit(20)
	content_type 'application/atom+xml', :charset => 'utf-8'
	builder :feed
end

get '/rss' do
	redirect '/feed', 301
end

### Admin

get '/auth' do
	erb :auth
end

post '/auth' do
	response.set_cookie(Blog.admin_cookie_key.to_s, Blog.admin_cookie_value) if params[:password] == Blog.admin_password
	redirect '/'
end

get '/posts/new' do
	auth
	erb :new, :locals => { :post => Post.new, :url => '/posts' }
end

post '/posts' do
	auth
	post = Post.new :title => params[:title], :tags => params[:tags], :body => params[:body], :created_at => Time.now, :slug => Post.make_slug(params[:title])
	post.save
	redirect post.url
end

get '/past/:year/:month/:day/:slug/edit' do
	auth
	post = Post.filter(:slug => params[:slug]).first
	not_found unless post
	erb :edit, :locals => { :post => post, :url => post.url }
end

get '/past/:year/:month/:day/:slug/delete' do
	auth
	post = Post.filter(:slug => params[:slug]).first
	not_found unless post
	post.destroy
	redirect '/'
end

post '/past/:year/:month/:day/:slug/' do
	auth
	post = Post.filter(:slug => params[:slug]).first
	not_found unless post
	post.title = params[:title]
	post.tags = params[:tags]
	post.body = params[:body]
	post.save
	redirect post.url
end
