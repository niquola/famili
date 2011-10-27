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
      user { Famili::User.create }
      title { "article by #{user.last_name}" }
    end
  end

  class UserFamili < Famili::Mother
    first_name { 'john' }
    last_name { 'smith' }
    login { "#{last_name}_#{first_name}" }
    last_login_datetime { created_at }
    created_at { Time.now - Random.rand(1000) }

    scope :russian do
      first_name { 'ivan' }
      last_name { 'petrov' }
    end
  end

  it "should have access to Kernel functions" do
    user = UserFamili.create(:last_name => ->{ "smith_#{rand(100)}" })
    user.last_name.should be_start_with("smith_")
  end

  it "should auto-evaluate model class" do
    Famili::User.send(:model_class).should == User
    UserFamili.send(:model_class).should == User
  end

  describe "scopes" do
    it "should override default values with values from scope" do
      user = UserFamili.russian.create
      user.first_name.should == 'ivan'
      user.last_name.should == 'petrov'
      user.login.should == "petrov_ivan"
    end
  end

  it "should calculate field value only once and cache" do
    user = UserFamili.create
    user.created_at.should == user.last_login_datetime
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

  it "mother should have #build_hash method returning symbolized hash" do
    hash = Famili::User.build_hash
    hash.keys.each { |key| key.should be_kind_of(Symbol) }
  end

  it "should create model with association" do
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
      logins << Famili::User.build_hash[:login]
    end
    logins.include?(Famili::User.build_hash[:login]).should_not be_true
  end

  it "should not add attribute name" do
    Famili::User.name
    Famili::User.attributes.should_not include(:name)
    lambda {
      Famili::User.unexisting
    }.should raise_error(NoMethodError)
  end
end
