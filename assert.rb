#!/usr/bin/env ruby
# -*- ruby -*-

begin
  require 'win32console'
rescue LoadError
end

# --------------------------------------------------------------------
# Support code for the Ruby Koans.
# --------------------------------------------------------------------

class FillMeInError < StandardError
end

def ruby_version?(version)
  RUBY_VERSION =~ /^#{version}/ ||
    (version == 'jruby' && defined?(JRUBY_VERSION)) ||
    (version == 'mri' && ! defined?(JRUBY_VERSION))
end

def in_ruby_version(*versions)
  yield if versions.any? { |v| ruby_version?(v) }
end

in_ruby_version("1.8") do
  class KeyError < StandardError
  end
end

# Standard, generic replacement value.
# If value19 is given, it is used in place of value for Ruby 1.9.
def __(value="THE __ TEXT (you fill it in)", value19=:mu)
  if RUBY_VERSION < "1.9"
    value
  else
    (value19 == :mu) ? value : value19
  end
end

# Numeric replacement value.
def _n_(value=999999, value19=:mu)
  if RUBY_VERSION < "1.9"
    value
  else
    (value19 == :mu) ? value : value19
  end
end

# Error object replacement value.
def ___(value=FillMeInError, value19=:mu)
  if RUBY_VERSION < "1.9"
    value
  else
    (value19 == :mu) ? value : value19
  end
end

# Method name replacement.
class Object
  def ____(method=nil)
    if method
      self.send(method)
    end
  end

  in_ruby_version("1.9", "2") do
    public :method_missing
  end
end

class String
  def side_padding(width)
    extra = width - self.size
    if width < 0
      self
    else
      left_padding = extra / 2
      right_padding = (extra+1)/2
      (" " * left_padding) + self + (" " *right_padding)
    end
  end
end

module Neo
  class << self
    def simple_output
      ENV['SIMPLE_KOAN_OUTPUT'] == 'true'
    end
  end

  module Assertions
    FailedAssertionError = Class.new(StandardError)

    def flunk(msg)
      raise FailedAssertionError, msg
    end

    def assert(condition, msg=nil)
      msg ||= "Failed assertion."
      flunk(msg) unless condition
      true
    end

    def assert_equal(expected, actual, msg=nil)
      msg ||= "Expected #{expected.inspect} to equal #{actual.inspect}"
      assert(expected == actual, msg)
    end

    def assert_not_equal(expected, actual, msg=nil)
      msg ||= "Expected #{expected.inspect} to not equal #{actual.inspect}"
      assert(expected != actual, msg)
    end

    def assert_nil(actual, msg=nil)
      msg ||= "Expected #{actual.inspect} to be nil"
      assert(nil == actual, msg)
    end

    def assert_not_nil(actual, msg=nil)
      msg ||= "Expected #{actual.inspect} to not be nil"
      assert(nil != actual, msg)
    end

    def assert_match(pattern, actual, msg=nil)
      msg ||= "Expected #{actual.inspect} to match #{pattern.inspect}"
      assert pattern =~ actual, msg
    end

    def assert_raise(exception)
      begin
        yield
      rescue Exception => ex
        expected = ex.is_a?(exception)
        assert(expected, "Exception #{exception.inspect} expected, but #{ex.inspect} was raised")
        return ex
      end
      flunk "Exception #{exception.inspect} expected, but nothing raised"
    end

    def assert_nothing_raised
      begin
        yield
      rescue Exception => ex
        flunk "Expected nothing to be raised, but exception #{exception.inspect} was raised"
      end
    end
  end

  class Sensei
    attr_reader :failure, :failed_test

    FailedAssertionError = Assertions::FailedAssertionError

    def initialize
      @failure = nil
      @failed_test = nil
      @observations = []
    end

    def observe(step)
      unless step.passed?
        @failed_test = step
        @failure = step.failure
        @observations << "#{step.koan_file}##{step.name} has damaged your karma."
        throw :neo_exit
      end
    end

    def failed?
      ! @failure.nil?
    end

    def assert_failed?
      failure.is_a?(FailedAssertionError)
    end

    def instruct
      if failed?
        @observations.each{|c| puts c }
        guide_through_error
      else
        end_screen
      end
    end

    def end_screen
      if Neo.simple_output
        boring_end_screen
      else
        artistic_end_screen
      end
    end

    def boring_end_screen
      puts "Mountains are again merely mountains"
    end

    def artistic_end_screen
      "JRuby 1.9.x Koans"
      ruby_version = "(in #{'J' if defined?(JRUBY_VERSION)}Ruby #{defined?(JRUBY_VERSION) ? JRUBY_VERSION : RUBY_VERSION})"
      ruby_version = ruby_version.side_padding(54)
        completed = <<-ENDTEXT
                                  ,,   ,  ,,
                                :      ::::,    :::,
                   ,        ,,: :::::::::::::,,  ::::   :  ,
                 ,       ,,,   ,:::::::::::::::::::,  ,:  ,: ,,
            :,        ::,  , , :, ,::::::::::::::::::, :::  ,::::
           :   :    ::,                          ,:::::::: ::, ,::::
          ,     ,:::::                                  :,:::::::,::::,
      ,:     , ,:,,:                                       :::::::::::::
     ::,:   ,,:::,                                           ,::::::::::::,
    ,:::, :,,:::                                               ::::::::::::,
   ,::: :::::::,       Mountains are again merely mountains     ,::::::::::::
   :::,,,::::::                                                   ::::::::::::
 ,:::::::::::,                                                    ::::::::::::,
 :::::::::::,                                                     ,::::::::::::
:::::::::::::                                                     ,::::::::::::
::::::::::::                      Ruby Koans                       ::::::::::::
::::::::::::#{                  ruby_version                     },::::::::::::
:::::::::::,                                                      , :::::::::::
,:::::::::::::,                brought to you by                 ,,::::::::::::
::::::::::::::                                                    ,::::::::::::
 ::::::::::::::,                                                 ,:::::::::::::
 ::::::::::::,               Neo Software Artisans              , ::::::::::::
  :,::::::::: ::::                                               :::::::::::::
   ,:::::::::::  ,:                                          ,,:::::::::::::,
     ::::::::::::                                           ,::::::::::::::,
      :::::::::::::::::,                                  ::::::::::::::::
       :::::::::::::::::::,                             ::::::::::::::::
        ::::::::::::::::::::::,                     ,::::,:, , ::::,:::
          :::::::::::::::::::::::,               ::,: ::,::, ,,: ::::
              ,::::::::::::::::::::              ::,,  , ,,  ,::::
                 ,::::::::::::::::              ::,, ,   ,:::,
                      ,::::                         , ,,
                                                  ,,,
ENDTEXT
        puts completed
    end

    def guide_through_error
      puts
      puts "The answers you seek..."
      puts indent(failure.message).join
      puts
      puts "Please meditate on the following code:"
      puts indent(find_interesting_lines(failure.backtrace))
      puts
    end

    def indent(text)
      text = text.split(/\n/) if text.is_a?(String)
      text.collect{|t| "  #{t}"}
    end

    def find_interesting_lines(backtrace)
      backtrace.reject { |line|
        line =~ /neo\.rb/ || line.start_with?("/")
      }
    end
  end

  class Koan
    include Assertions

    attr_reader :name, :failure, :koan_count, :step_count, :koan_file

    def initialize(name, koan_file=nil, koan_count=0, step_count=0)
      @name = name
      @failure = nil
      @koan_count = koan_count
      @step_count = step_count
      @koan_file = koan_file
    end

    def passed?
      @failure.nil?
    end

    def failed(failure)
      @failure = failure
    end

    def setup
    end

    def teardown
    end

    def meditate
      setup
      begin
        send(name)
      rescue StandardError, Neo::Sensei::FailedAssertionError => ex
        failed(ex)
      ensure
        begin
          teardown
        rescue StandardError, Neo::Sensei::FailedAssertionError => ex
          failed(ex) if passed?
        end
      end
      self
    end

    # Class methods for the Neo test suite.
    class << self
      def inherited(subclass)
        subclasses << subclass
      end

      def method_added(name)
        testmethods << name if !tests_disabled? && Koan.test_pattern =~ name.to_s
      end

      def end_of_enlightenment
        @tests_disabled = true
      end

      def command_line(args)
        args.each do |arg|
          case arg
          when /^-n\/(.*)\/$/
            @test_pattern = Regexp.new($1)
          when /^-n(.*)$/
            @test_pattern = Regexp.new(Regexp.quote($1))
          else
            if File.exist?(arg)
              load(arg)
            else
              fail "Unknown command line argument '#{arg}'"
            end
          end
        end
      end

      # Lazy initialize list of subclasses
      def subclasses
        @subclasses ||= []
      end

       # Lazy initialize list of test methods.
      def testmethods
        @test_methods ||= []
      end

      def tests_disabled?
        @tests_disabled ||= false
      end

      def test_pattern
        @test_pattern ||= /^test_/
      end

      def total_tests
        self.subclasses.inject(0){|total, k| total + k.testmethods.size }
      end
    end
  end

  class ThePath
    def walk
      sensei = Neo::Sensei.new
      each_step do |step|
        sensei.observe(step.meditate)
      end
      sensei.instruct
    end

    def each_step
      catch(:neo_exit) {
        step_count = 0
        Neo::Koan.subclasses.each_with_index do |koan,koan_index|
          koan.testmethods.each do |method_name|
            step = koan.new(method_name, koan.to_s, koan_index+1, step_count+=1)
            yield step
          end
        end
      }
    end
  end
end

END {
  Neo::Koan.command_line(ARGV)
  Neo::ThePath.new.walk
}
