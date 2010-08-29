require 'spec_helper'

describe Famili do
  before :all do
    TestDbUtils.ensure_schema
  end

  after :all do
    #TestDbUtils.drop_database
  end

  class User < ActiveRecord::Base
  end

  module Famili
    class User < Mother
      last_name { 'nicola' }

      def before_save(user)
        user.first_name = 'first_name' 
      end

      def after_create(model)
      end
    end
  end

  it "should create model" do
    nicola = Famili::User.create 
    nicola.class.should == User
    nicola.last_name.should == 'nicola'
    nicola.first_name.should == 'first_name'

    ivan = Famili::User.create(:name=>'ivan')
    ivan.name.should == 'ivan'
  end
end
