map "/" do
    use Rack::Static, 
          :urls => [""], :root => "public", :index => 'index.html.erb'
    run lambda {|*|}
end

