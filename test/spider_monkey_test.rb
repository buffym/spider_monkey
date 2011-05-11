$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'spider_monkey'
require 'fakeweb'

class SpiderMonkeyTest < Test::Unit::TestCase

  SPIDER_TEST_FILE = File.join(File.expand_path(File.dirname(__FILE__)), 'test.html')
  
  def test_broken
    FakeWeb.register_uri(:get, 'http://testurlnow.com', :body => File.read(SPIDER_TEST_FILE), :status => ["200", "OK"])

    s = SpiderMonkey::Finder.new('http://testurlnow.com')
    assert(s.broken.include?('http://testurlnow.com/relative.jpg'))
    assert(s.broken.include?('http://testurlnow.com/absolute.jpg'))
    assert(s.broken.include?('http://testurlnow.com/relative.html'))
    assert(s.broken.include?('http://testurlnow.com/absolute.html'))
    assert(s.broken.include?('http://www.google.com/idontexist'))
  end

  def test_live
    FakeWeb.register_uri(:get, 'http://testurlnow.com/relative.html', :body => "hi", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, 'http://testurlnow.com/absolute.html', :body => "hi", :status => ["200", "OK"])
    FakeWeb.register_uri(:head, 'http://testurlnow.com/relative.jpg', :body => "hi", :status => ["200", "OK"])
    FakeWeb.register_uri(:head, 'http://testurlnow.com/absolute.jpg', :body => "hi", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, 'http://testurlnow.com', :body => File.read(SPIDER_TEST_FILE), :status => ["200", "OK"])

    s = SpiderMonkey::Finder.new('http://testurlnow.com')
    assert_false(s.broken.include?('http://testurlnow.com/relative.jpg'))
    assert_false(s.broken.include?('http://testurlnow.com/absolute.jpg'))
    assert_false(s.broken.include?('http://testurlnow.com/relative.html'))
    assert_false(s.broken.include?('http://testurlnow.com/absolute.html'))
    assert_false(s.broken.include?('http://www.google.com'))
  end

end
