files_to_process = Dir.glob("src/*.xml")
require "rexml/document"
require "erb"

def acts(doc)
  acts = []
  doc.elements.each('PLAY/ACT') do |a|
    act = {}
    a.elements.each('TITLE') do |t|
      act[:title] =  t.text
    end
    act[:prologue] = scenes(a,'PROLOGUE').first
    act[:scenes] = scenes(a,'SCENE') 
    act[:epilogue] = scenes(a,'EPILOGUE').first
    acts << act
  end
  return acts
end

def pline(l)
  lines= []
  l.children.each do |c|
    case c.node_type
    when :text
      lines << c
    when :element
      lines<< {:stagedir => c.text}
    end
  end
  lines
end

def speech(l)
  speech = { speakers: [], lines: []}
  l.elements.each do |s|
      case s.name
        when 'SPEAKER'
          speech[:speakers] << s.text 
        when 'LINE'
          speech[:lines] << pline(s) 
        when 'STAGEDIR','SUBHEAD'
          speech[:lines] << {:stagedir => s.text} 
      end
  end
  speech
end

def scenes(doc,elem)
  scenes = []
  doc.elements.each(elem) do |s|
    scene = {}
    s.elements.each('TITLE') do |t|
      scene[:title] = t.text
    end
    scenes << scene
    scene[:parts] = []
    s.elements.each do |l|
      case l.name
        when 'SPEECH'
          scene[:parts] << speech(l)
        when 'STAGEDIR','SUBHEAD'
          scene[:parts] << {:stagedir => l.text} 
      end
    end
  end
  scenes
end

index = []
template = ERB.new(File.read("etc/play.erb"))
files_to_process.each do |f|
  play = {}
  doc = REXML::Document.new(File.new(f))

  doc.elements.each('PLAY/TITLE') do |t|
    play[:title] = t.text
  end 
  doc.elements.each('PLAY/PLAYSUBT') do |t|
    play[:subtitle] = t.text 
  end 
  play[:prologue] = scenes(doc,'PLAY/PROLOGUE').first
  play[:acts] = acts(doc)
  play[:epilogue] = scenes(doc,'PLAY/EPILOGUE').first

  html = template.result(binding)
  puts f
  out = File.new(f.gsub("xml","html").gsub("src/","public/"),"w")
  out.write html
  puts "WRITING #{out}"
  index << {:title => play[:title], :subtitle => play[:subtitle], :file => File.basename(out)}
end
index_file = File.new("public/index.html", "w")
index_temp = ERB.new(File.read("etc/index.erb"))
html = index_temp.result(binding)
index_file.write html
