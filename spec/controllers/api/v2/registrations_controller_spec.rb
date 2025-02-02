#***** BEGIN LICENSE BLOCK *****
#
#Version: RTV Public License 1.0
#
#The contents of this file are subject to the RTV Public License Version 1.0 (the
#"License"); you may not use this file except in compliance with the License. You
#may obtain a copy of the License at: http://www.osdv.org/license12b/
#
#Software distributed under the License is distributed on an "AS IS" basis,
#WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
#specific language governing rights and limitations under the License.
#
#The Original Code is the Online Voter Registration Assistant and Partner Portal.
#
#The Initial Developer of the Original Code is Rock The Vote. Portions created by
#RockTheVote are Copyright (C) RockTheVote. All Rights Reserved. The Original
#Code contains portions Copyright [2008] Open Source Digital Voting Foundation,
#and such portions are licensed to you under this license by Rock the Vote under
#permission of Open Source Digital Voting Foundation.  All Rights Reserved.
#
#Contributor(s): Open Source Digital Voting Foundation, RockTheVote,
#                Pivotal Labs, Oregon State University Open Source Lab.
#
#***** END LICENSE BLOCK *****
require File.expand_path(File.dirname(__FILE__) + '/../../../rails_helper')

describe Api::V2::RegistrationsController do

  describe 'create' do
    it 'should return URL of PDF to be generated' do
      expect_api_response :pdfurl => "https://example-pdf.com/123.pdf"
      registrant= double(Registrant)
      registrant.stub(:pdf_download_path) { '/123.pdf' }
      new_registration { registrant  }
    end

    it 'should catch invalid fields' do
      expect_api_error :message => "Error message", :field_name => "invalid_field"
      new_registration { raise V2::RegistrationService::ValidationError.new('invalid_field', 'Error message') }
    end

    it 'should report unsupported language' do
      expect_api_error :message => 'Unsupported language'
      new_registration { raise V2::UnsupportedLanguageError }
    end

    it 'should report invalid parameter type' do
      expect_api_error :message => "Invalid parameter type", :field_name => "attr"
      new_registration { raise(ActiveRecord::UnknownAttributeError.new(Registrant.new, 'attr')) }
    end

    [ 1, 2 ].each do |qnum|
      it "should report error when an answer is provided without a question" do
        expect_api_error :message =>"Question #{qnum} required when Answer #{qnum} provided"
        new_registration { raise(V2::RegistrationService::SurveyQuestionError.new("Question #{qnum} required when Answer #{qnum} provided")) }
      end
    end
  end

  describe 'create_finish_with_state' do
    it 'should render nothing when success' do
      reg = FactoryGirl.create(:step_2_registrant)
      expect_api_response :registrations => reg.to_finish_with_state_array
      new_finish_with_state_registration  { reg }
    end
  end

  describe 'index' do
    it 'should catch errors' do
      expect_api_error :message => 'error'
      registrations { raise ArgumentError.new('error') }
    end

    it 'should return registrations' do
      expect_api_response :registrations => [ :reg1, :reg2 ]
      registrations { [ :reg1, :reg2 ] }
    end
  end
  
  describe "index_gpartner" do
    it 'should catch errors' do
      expect_api_error :message => 'error'
      gregistrations { raise ArgumentError.new('error') }
    end
    it 'should return registrations' do
      expect_api_response :registrations => [ :reg1, :reg2 ]
      gregistrations { [ :reg1, :reg2 ] }
    end    
  end

  private

  def registrations(&block)
    query = { :partner_id => nil, :partner_api_key => nil, :since => nil, :email=>nil }
    V2::RegistrationService.stub(:find_records).with(query, &block)
    get :index, :format => 'json'
  end
  def gregistrations(&block)
    query = { :gpartner_id => nil, :gpartner_api_key => nil, :since => nil, :email=>nil }
    V2::RegistrationService.stub(:find_records).with(query, &block)
    get :index_gpartner, :format => 'json'
  end

  def new_registration(&block)
    data = {}
    V2::RegistrationService.stub(:create_record).with(data, &block)
    post :create, :format => 'json', :registration => data
  end

  def new_finish_with_state_registration(&block)
    data = { 'lang' => 'en', 'partner_id' => Partner.first.id }
    V2::RegistrationService.stub(:create_record).with(data, true, &block)
    post :create_finish_with_state, :format => 'json', :registration => data
  end

end
