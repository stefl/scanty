require 'rubygems'
require 'maruku'
require 'dm-core'
require 'do_postgres'
require 'dm-postgres-adapter'
require 'dm-migrations'
require 'dm-timestamps'
require 'haml'
require 'haml/html'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../vendor/syntax'
require 'syntax/convertors/html'

db_conf = ENV['DATABASE_URL'] || 'postgres://postgres:postgres@localhost/stefio'
STDERR.puts db_conf

DataMapper.setup(:default, db_conf)

class Post
  include DataMapper::Resource
  
  property :id, Integer, :key=>true
  property :title, String, :length=>255
  property :body, Text
  property :slug, String, :length=>255
  property :tags, String
  property :created_at, DateTime
  property :published_at, DateTime
  property :format, String, :default=>"haml"
  
	def url
		d = published_at
		"/#{d.year}/#{d.month}/#{slug}/"
	end

	def full_url
		Blog.url_base.gsub(/\/$/, '') + url
	end

	def body_html
	  case format
      when "haml"
        Haml::Engine.new(body).render("post body")
      when "html"
        to_html(body)
    end
		
	end

	def summary
		@summary ||= body.match(/(.{600}.*?\n)/m)
		@summary || body
	end

	def summary_html
		to_html(summary.to_s)
	end

	def more?
		@more ||= body.match(/.{600}.*?\n(.*)/m)
		@more
	end

	def linked_tags
		tags.split.inject([]) do |accum, tag|
			accum << "<a href=\"/past/tags/#{tag}\">#{tag}</a>"
		end.join(" ")
	end

	def self.make_slug(title)
		title.downcase.gsub(/ /, '_').gsub(/[^a-z0-9_]/, '').squeeze('_')
	end

	########

	def to_html(markdown)
		out = []
		noncode = []
		code_block = nil
		markdown.split("\n").each do |line|
			if !code_block and line.strip.downcase == '<code>'
				out << Maruku.new(noncode.join("\n")).to_html
				noncode = []
				code_block = []
			elsif code_block and line.strip.downcase == '</code>'
				convertor = Syntax::Convertors::HTML.for_syntax "ruby"
				highlighted = convertor.convert(code_block.join("\n"))
				out << "<code>#{highlighted}</code>"
				code_block = nil
			elsif code_block
				code_block << line
			else
				noncode << line
			end
		end
		out << Maruku.new(noncode.join("\n")).to_html
		out.join("\n")
	end

	def split_content(string)
		parts = string.gsub(/\r/, '').split("\n\n")
		show = []
		hide = []
		parts.each do |part|
			if show.join.length < 100
				show << part
			else
				hide << part
			end
		end
		[ to_html(show.join("\n\n")), hide.size > 0 ]
	end
end

DataMapper.auto_upgrade!