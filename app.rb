require 'sinatra'
require 'bibtex'
require 'English'

set :public_folder, File.dirname(__FILE__) + '/_site'
set :bibfile, File.join(File.dirname(__FILE__), 'lib.bib')

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

get '/:name' do |n|
  "Create page for #{n}"
end

get %r{/notes/([^.]+)(\.md)?} do
  citekey = params[:captures].first
  b = BibTeX.open(settings.bibfile)

  if entry = b[citekey]
    title = entry.title.tr("{}","")
  else
    title = "unknown citation"
  end

  content = nil

  existing_notes_file = File.join('notes', "#{citekey}.md")
  if File.exists? existing_notes_file
    File.open(existing_notes_file, 'r') do |f| 
      content = f.read
    end
  end

  if content =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
    content = $POSTMATCH
  end

  erb :edit, locals: { filename: "#{citekey}.md", title: title, content: content, namespace: 'notes', contentonly: true }
end

post '/pages' do
  ns = params[:page][:namespace]
  fn = params[:page][:filename]
  file = File.join(ns, fn)

  File.open(file, 'w') do |f|
    if title = params[:page][:title]
      f.puts "---"
      f.puts "title: #{title}"
      f.puts "---"
    end
    f.puts params[:page][:content]
  end

  redirect "/#{ns}/#{fn}"
end
