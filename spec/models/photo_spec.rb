require File.dirname(__FILE__) + '/../spec_helper'

describe Photo do
  before do
    @user = Factory.create(:user)
    @fixture_name = File.dirname(__FILE__) + '/../fixtures/bp.jpeg'
    @fail_fixture_name = File.dirname(__FILE__) + '/../fixtures/msg.xml'
    @album = Album.create(:name => "foo", :person => @user)
    @photo = Photo.new(:person => @user, :album => @album)
  end

  it 'should have a constructor' do
    photo = Photo.instantiate(:person => @user, :album => @album, :image => File.open(@fixture_name)) 
    photo.save.should be true
    photo.image.read.nil?.should be false
  end

  it 'should save a @photo to GridFS' do
    file = File.open(@fixture_name)
    @photo.image = file
    @photo.save.should == true
    binary = @photo.image.read
    fixture_binary = File.open(@fixture_name).read
    binary.should == fixture_binary
  end

  it  'must have an album' do

    photo = Photo.new(:person => @user)
    file = File.open(@fixture_name)
    photo.image = file
    photo.save
    photo.valid?.should be false
    photo.album = Album.create(:name => "foo", :person => @user)
    photo.save
    Photo.first.album.name.should == 'foo'
  end

  describe 'non-image files' do
    it 'should not store' do
      file = File.open(@fail_fixture_name)
      @photo.image.should_receive(:check_whitelist!)
      lambda {
        @photo.image.store! file
      }.should raise_error
    end

    it 'should not save' do
      pending "We need to figure out the difference between us and the example app"
      file = File.open(@fail_fixture_name)
      @photo.image.should_receive(:check_whitelist!)
      @photo.image = file
      @photo.save.should == false
    end



  end

  describe 'with encryption' do
    
    before do
      unstub_mocha_stubs
    end
    
    after do
      stub_signature_verification
    end

    it 'should save a signed @photo to GridFS' do
      photo  = Photo.instantiate(:person => @user, :album => @album, :image => File.open(@fixture_name))
      photo.save.should == true
      photo.verify_creator_signature.should be true
    end
    
  end

  describe 'remote photos' do
    it 'should write the url on serialization' do 
      @photo.image = File.open(@fixture_name)
      @photo.image.store!
      @photo.save
      xml = @photo.to_xml.to_s
      xml.include?(@photo.image.url).should be true
    end
    it 'should have an album id on serialization' do
       @photo.image = File.open(@fixture_name)
      xml = @photo.to_xml.to_s
      xml.include?(@photo.album.id.to_s).should be true
    end
  end
end
