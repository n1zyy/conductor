#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'spec_helper'

describe Api::HooksController do
  render_views

  context "when authenticated as admin" do

    before(:each) do
      send_and_accept_xml
      @admin_permission = FactoryGirl.create :admin_permission
      @admin = @admin_permission.user
      mock_warden(@admin)
    end

    describe "#index" do

      context "when there are no hooks" do

        before(:each) do
          get :index
        end

        it { response.should be_success }
        it { response.headers['Content-Type'].should include("application/xml") }
        it "should have no hooks" do
          resp = Hash.from_xml(response.body)
          resp['hooks']['hooks'].should be_nil
        end

      end

      context "when there are 2 hooks" do

        before(:each) do
          @hooks = []
          @hooks << Factory.create(:hook)
          @hooks << Factory.create(:hook, :uri => 'https://pcloud.org/events')
          get :index
        end

        it { response.should be_success }
        it { response.headers['Content-Type'].should include("application/xml") }
        it "should have hooks with correct attributes" do
          resp = Hash.from_xml(response.body)
          hooks = resp['hooks']['hook']

          hooks.should have(2).things
          hooks.first['uri'].should == @hooks.first.uri
          hooks.last['uri'].should == @hooks.last.uri
        end
      end
    end



    describe "#show" do
      context "when there are no hooks" do
        before(:each) do
          get :show, :id => 5
        end

        it { response.should_not be_success }
        it { response.headers['Content-Type'].should include("application/xml") }

        it "should return 404" do
          response.status.should == 404
        end

      end

      context "when there is 1 hook" do
        before(:each) do
          @hook = Factory.create(:hook)
        end

        it "should return the requested hook" do
          get :show, :id => @hook.id

          response.should be_success
          response.headers['Content-Type'].should include("application/xml")

          resp = Hash.from_xml(response.body)
          hook = resp['hook']
          hook.should_not be_blank
          hook['uri'].should == @hook.uri
          hook['version'].should == @hook.version
        end

        it "should return 404 for nonexistent hook" do
          get :show, :id => 52983

          response.status.should == 404
          response.headers['Content-Type'].should include("application/xml")
        end
      end
    end

    describe "#create" do

      it "should return 501 for unknown version" do
        post :create, :hook => Factory.attributes_for(:hook, :version => '273')
        response.status.should == 501
      end

      it "should return 501 for missing version" do
        post :create, :hook => Factory.attributes_for(:hook, :version => nil)
        response.status.should == 501
      end

      it "should return 400 for missing data" do
        post :create
        response.status.should == 400
      end

      it "should return 400 for invalid hook data" do
        post :create, :hook => Factory.attributes_for(:hook, :uri => nil)
        response.status.should == 400

        post :create, :hook => Factory.attributes_for(:hook, :uri => '')
        response.status.should == 400
      end

      it "should register a new hook" do
        new_hook = Factory.attributes_for(:hook)
        post :create, :hook => new_hook

        response.should be_success
        response.headers['Content-Type'].should include("application/xml")
        response.headers['Location'].should include("/api/hooks/")

        resp = Hash.from_xml(response.body)
        hook = resp['hook']
        hook.should_not be_blank
        hook['uri'].should == new_hook[:uri]
      end

    end

    describe "#destroy" do
      context "when there are no hooks" do
        before(:each) do
          delete :destroy, :id => 29830
        end

        it { response.should_not be_success }
        it { response.headers['Content-Type'].should include("application/xml") }

        it "should return 404" do
          response.status.should == 404
        end
      end

      context "when there is 1 hook" do
        before(:each) do
          @hook = Factory.create(:hook)
        end

        it "should delete requested hook" do
          delete :destroy, :id => @hook.id
          response.status.should == 204
        end

        it "should return 404 for nonexistent hook" do
          delete :destroy, :id => 52983
          response.status.should == 404
        end
      end
    end
  end

  context "when not logged in" do

    before(:each) do
      send_and_accept_xml
      @hook = Factory.create(:hook)
      mock_warden(nil)
    end

    it "index should return 401" do
      get :index
      response.status.should == 401
    end

    it "show should return 401" do
      get :show, :id => @hook.id
      response.status.should == 401
    end

    it "create should return 401" do
      post :create, :hook => Factory.create(:hook)
      response.status.should == 401
    end

    it "destroy should return 401" do
      delete :destroy, :id => @hook.id
      response.status.should == 401
    end
  end

end
