require 'spider_monkey'

if __FILE__ == $0
  unless ARGV[0]
    puts "Usage: spider_monkey url_to_check"
    exit(1)
  end

  url = ARGV[0].strip
  SpiderMonkey::Finder.new(url).broken.each { |link| puts link}
  exit(0)
end
