$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
module Famili
  VERSION='0.0.3'
  autoload :Mother,'famili/mother'
end
