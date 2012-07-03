require 'spec_helper'
require "uuid"

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

    def nickname=(value)
      @nickname = value
    end

    def calculate_nickname
      @nickname || @login
    end

    def method_missing(name, *args)
      if name.to_s == "not_defined_method"
        "#{name} is not defined"
      else
        super
      end
    end
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
  end

  class ArticleFamili < Famili::Mother
    has :user do
      last_name { 'nicola' }
    end

    title { "article by #{user.last_name}" }
  end

  class CommentableArticleFamili < ArticleFamili
    self.model_class = Article

    title { "cmt article by #{user.last_name}" }
  end

  class UserFamili < Famili::Mother
    first_name { 'john' }
    last_name { 'smith' }
    login { "#{last_name}_#{first_name}" }
    last_login_datetime { created_at }
    created_at { Time.now - Random.rand(1000) }
    seq_no { sequence_number }

    def mother_random(n)
      rand(n)
    end

    scope :russian do
      first_name { 'ivan' }
      last_name { 'petrov' }
    end

    scope :unidentified do
      last_name { 'unknown' }
    end
  end

  it "should have access to Kernel functions" do
    user = UserFamili.create(:last_name => -> { "smith_#{rand(100)}" })
    user.last_name.should =~ /smith_\d{1,3}/
  end

  it "should delegate method call to mother" do
    user = UserFamili.create(:last_name => -> { "smith_#{mother_random(100)}" })
    user.last_name.should =~ /smith_\d{1,3}/
  end

  it "should auto-evaluate model class" do
    Famili::User.send(:model_class).should == User
    UserFamili.send(:model_class).should == User
  end

  it "should be evaluated in context of model" do
    user = UserFamili.create :login => -> { self.to_s }
    user.login.should == user.to_s
  end

  it "should bypass method_missing to model" do
    user = UserFamili.create :login => -> { not_defined_method }
    user.login.should == "not_defined_method is not defined"
  end

  it "should create model with only set access propeties" do
    user = UserFamili.create(:nickname => -> { "Mr #{login}" })
    user.calculate_nickname.should == "Mr #{user.login}"
  end

  describe "scopes" do
    it "should create from scope" do
      user = UserFamili.russian.create({})
      user.first_name.should == 'ivan'
      user.last_name.should == 'petrov'
      user.login.should == "petrov_ivan"
    end

    it "should build from scope" do
      user = UserFamili.russian.build({})
      user.first_name.should == 'ivan'
      user.last_name.should == 'petrov'
      user.login.should == "petrov_ivan"
    end

    it "should build_hash from scope" do
      hash = UserFamili.russian.build_hash
      hash[:first_name].should == 'ivan'
      hash[:last_name].should == 'petrov'
      hash[:login].should == 'petrov_ivan'
    end

    it "should chain scopes" do
      user = UserFamili.russian.unidentified.build
      user.first_name.should == 'ivan'
      user.last_name.should == 'unknown'
      user.login.should == 'unknown_ivan'
    end

    it "should support anonymous scope" do
      shared = UserFamili.scoped(:first_name => 'jeffry')
      shared.create(:last_name => 'stone').login.should == 'stone_jeffry'
      shared.create(:last_name => 'snow').login.should == 'snow_jeffry'
      shared.unidentified.create.login.should == 'unknown_jeffry'
    end
  end

  describe "brothers" do
    it "should build brothers" do
      brothers = UserFamili.build_brothers(2, :login => -> { "#{last_name}_#{first_name}_#{rand(100)}" })
      first, second = brothers
      first.should_not be_persisted
      second.should_not be_persisted
      first.first_name.should == second.first_name
      first.last_name.should == second.last_name
      first.login.should_not == second.login
    end

    it "should create brothers" do
      brothers = UserFamili.create_brothers(2, :login => -> { UUID.generate })
      first, second = brothers
      first.should be_persisted
      second.should be_persisted
      first.first_name.should == second.first_name
      first.last_name.should == second.last_name
      first.login.should_not == second.login
    end

    it "should build brothers with init block" do
      brothers = UserFamili.build_brothers(1) { |brother| brother.login = "#{brother.login}_#{rand(100)}" }
      brothers += UserFamili.build_brothers(1) { |brother, i| brother.login = "#{brother.login}_#{i}" }
      first, second = brothers
      first.should_not be_persisted
      second.should_not be_persisted
      first.first_name.should == second.first_name
      first.last_name.should == second.last_name
      first.login.should_not == second.login
      first.login.should =~ /#{first.last_name}_#{first.first_name}_\d{1,3}/
      second.login.should == "#{second.last_name}_#{second.first_name}_0"
    end
  end

  it "should calculate field value only once and cache" do
    user = UserFamili.create
    user.created_at.should == user.last_login_datetime
  end

  it "should use save! model" do
    lambda { Famili::User.create(:login => nil) }.should raise_error
  end

  it "should create model" do
    nicola = Famili::User.create
    nicola.class.should == User
    nicola.last_name.should == 'nicola'
    nicola.first_name.should == 'first_name'

    ivan = Famili::User.create(:name => 'ivan')
    ivan.name.should == 'ivan'
  end

  it "mother should have #build method" do
    user = UserFamili.build(:last_name => 'stone')
    user.last_name.should == 'stone'
    user.first_name.should == 'john'
  end

  it "mother should have #build_hash method returning symbolized hash" do
    hash = Famili::User.build_hash
    hash.keys.each { |key| key.should be_kind_of(Symbol) }
  end

  it "should create model with association" do
    article = ArticleFamili.create
    article.user.should_not be_nil
    article.user.class.should == ::User
    article.title.should == "article by nicola"
  end

  it "mother should have unique,sequence_number methods" do
    seq_number = UserFamili.build.seq_no
    next_seq_number = UserFamili.build.seq_no
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
  
  describe "associations" do
    it "should override association" do
      user = UserFamili.create
      article = ArticleFamili.create(user: user)
      article.user.should == user
    end
  end

  describe "inheritance" do
    it "should inherit associations" do
      commentable_article = CommentableArticleFamili.create
      commentable_article.user.last_name.should == 'nicola'
    end
  end
end
