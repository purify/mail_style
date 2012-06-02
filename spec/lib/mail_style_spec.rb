require 'spec_helper'

describe MailStyle do
  describe ".inline_css" do
    it "should create an instance of MailStyle::Inliner and execute it" do
      MailStyle::Inliner.should_receive(:new).with('attri', 'butes').and_return(double('inliner', :execute => 'html'))
      MailStyle.inline_css('attri', 'butes').should == 'html'
    end
  end

  describe ".load_css(root, targets)" do
    let(:fixtures_root) { Pathname.new(__FILE__).dirname.join('..', 'fixtures') }

    it "should load files matching the target names under root/public/stylesheets" do
      MailStyle.load_css(fixtures_root, ['foo']).should == 'contents of foo'
    end

    it "should load files in order and join them with a newline" do
      MailStyle.load_css(fixtures_root, %w[foo bar]).should == "contents of foo\ncontents of bar"
      MailStyle.load_css(fixtures_root, %w[bar foo]).should == "contents of bar\ncontents of foo"
    end

    it "should raise a MailStyle::CSSFileNotFound error when a css file could not be found" do
      expect { MailStyle.load_css(fixtures_root, ['not_here']) }.to raise_error(MailStyle::CSSFileNotFound, /not_here/)
    end
  end
end