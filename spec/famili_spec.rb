require 'spec_helper'

describe Famili do
  before :all do
    TestDbUtils.ensure_schema
  end

  after :all do
    TestDbUtils.drop_database
  end

  class User < ActiveRecord::Base
    has_many :articles
    validates_presence_of :login
  end

  class Article < ActiveRecord::Base
    belongs_to :user
  end

  module Famili
    class User < Mother
      last_name { 'nicola' }
      login { "#{last_name}_#{unique}" } 
      number { sequence_number }
      

      def before_save(user)
        user.first_name = 'first_name' 
      end

      def after_create(model)
      end
    end

    class Article < Mother
      user  { Famili::User.create }
      title { "article by #{user.last_name}" }
    end
  end

  it "should use save! model" do
    lambda { Famili::User.create(:login=>nil) }.should raise_error
  end

  it "should create model" do
    nicola = Famili::User.create 
    nicola.class.should == User
    nicola.last_name.should == 'nicola'
    nicola.first_name.should == 'first_name'

    ivan = Famili::User.create(:name=>'ivan')
    ivan.name.should == 'ivan'
  end

  it "mother should have #hash method returning symbolized hash" do
    hash = Famili::User.hash 
    hash.keys.each {|key| key.should be_kind_of(Symbol) }
  end


  it "should create model with asscociation" do
    article = Famili::Article.create
    article.user.should_not be_nil
    article.user.class.should == ::User
    article.title.should == "article by nicola"
  end

  it "mother should have unique,sequence_number methods" do
    Famili::User.new.should respond_to(:unique)
    Famili::User.new.should respond_to(:sequence_number)
    u1 = Famili::User.create
    u2 = Famili::User.create
    seq_number = Famili::User.new.sequence_number
    next_seq_number = Famili::User.new.sequence_number
    next_seq_number.should == (seq_number + 1)
  end

  it "mother should generate unique numbers" do
    logins = []
    10000.times do 
      logins << Famili::User.hash[:login]
    end
    logins.include?(Famili::User.hash[:login]).should_not be_true
  end

  it "should not add attribuite name" do
    Famili::User.name
    Famili::User.attribures.should_not include(:name)
    lambda {
      Famili::User.unexisting
    }.should raise_error(NoMethodError)
  end
end
