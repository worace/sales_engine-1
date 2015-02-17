require "ruby-prof"
puts "HELPER HERE"
RubyProf.start

Minitest.after_run do
  result = RubyProf.stop

  printer = RubyProf::MultiPrinter.new(result)
  printer.print(:path => "./tmp", :profile => "profile")

  printer = RubyProf::DotPrinter.new(result)
  File.open("./tmp/profile.dot", "w") do |f|
    printer.print(f)
  end
end
