require 'spec_helper'

describe Whois::Record::Parser do

  subject { described_class.new(record) }

  let(:record) { Whois::Record.new(nil, []) }


  describe ".parser_for" do
    it "returns the blank parser if the parser doesn't exist" do
      expect(described_class.parser_for(Whois::Record::Part.new(host: "whois.missing.test")).class.name).to eq("Whois::Record::Parser::Blank")
    end
  end

  describe ".parser_klass" do
    it "returns the parser hostname converted into a class" do
      require 'whois/record/parser/whois.crsnic.net'
      expect(described_class.parser_klass("whois.crsnic.net").name).to eq("Whois::Record::Parser::WhoisCrsnicNet")
    end

    it "recognizes and lazy-loads classes" do
      expect(described_class.parser_klass("whois.nic.it").name).to eq("Whois::Record::Parser::WhoisNicIt")
    end

    it "recognizes preloaded classes" do
      described_class.class_eval <<-RUBY
        class PreloadedParserTest
        end
      RUBY
      expect(described_class.parser_klass("preloaded.parser.test").name).to eq("Whois::Record::Parser::PreloadedParserTest")
    end

    it "raises LoadError if the parser doesn't exist" do
      expect { described_class.parser_klass("whois.missing.test") }.to raise_error(LoadError)
    end
  end

  describe ".host_to_parser" do
    it "works" do
      described_class.host_to_parser("whois.it").should == "WhoisIt"
      described_class.host_to_parser("whois.nic.it").should == "WhoisNicIt"
      described_class.host_to_parser("whois.domain-registry.nl").should == "WhoisDomainRegistryNl"
    end

    it "downcases hostnames" do
      described_class.host_to_parser("whois.PublicDomainRegistry.com").should == "WhoisPublicdomainregistryCom"
    end
  end


  describe "#initialize" do
    it "requires an record" do
      lambda { described_class.new }.should raise_error(ArgumentError)
      lambda { described_class.new(record) }.should_not raise_error
    end

    it "sets record from argument" do
      described_class.new(record).record.should be(record)
    end
  end

  describe "#respond_to?" do
    before(:all) do
      @_properties  = Whois::Record::Parser::PROPERTIES.dup
      @_methods     = Whois::Record::Parser::METHODS.dup
    end

    after(:all) do
      Whois::Record::Parser::PROPERTIES.clear
      Whois::Record::Parser::PROPERTIES.push(*@_properties)
      Whois::Record::Parser::METHODS.clear
      Whois::Record::Parser::METHODS.push(*@_methods)
    end

    it "returns true if method is in self" do
      subject.respond_to?(:to_s).should be_true
    end

    it "returns true if method is in hierarchy" do
      subject.respond_to?(:nil?).should be_true
    end

    it "returns true if method is a property" do
      Whois::Record::Parser::PROPERTIES << :test_property
      subject.respond_to?(:test_property).should be_true
    end

    it "returns false if method is a property?" do
      Whois::Record::Parser::PROPERTIES << :test_property
      subject.respond_to?(:test_property?).should be_false
    end

    it "returns true if method is a method" do
      Whois::Record::Parser::METHODS << :test_method
      subject.respond_to?(:test_method).should be_true
    end

    it "returns false if method is a method" do
      Whois::Record::Parser::METHODS << :test_method
      subject.respond_to?(:test_method?).should be_false
    end
  end


  describe "property lookup" do
    class Whois::Record::Parser::ParserSupportedTest < Whois::Record::Parser::Base
      property_supported :status do
        :status_supported
      end
      property_supported :created_on do
        :created_on_supported
      end
      property_supported :updated_on do
        :updated_on_supported
      end
      property_supported :expires_on do
        :expires_on_supported
      end
    end

    class Whois::Record::Parser::ParserUndefinedTest < Whois::Record::Parser::Base
      property_supported :status do
        :status_undefined
      end
      # not defined          :created_on
      # not defined          :updated_on
      # not defined          :expires_on
    end

    class Whois::Record::Parser::ParserUnsupportedTest < Whois::Record::Parser::Base
      property_not_supported :status
      property_not_supported :created_on
      property_not_supported :updated_on
      property_not_supported :expires_on
    end

    it "delegates to first parser when all supported" do
      r = Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "parser.supported.test"), Whois::Record::Part.new(:body => "", :host => "parser.undefined.test")])
      described_class.new(r).status.should == :status_undefined
      r = Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "parser.undefined.test"), Whois::Record::Part.new(:body => "", :host => "parser.supported.test")])
      described_class.new(r).status.should == :status_supported
    end

    it "delegates to first parser when one supported" do
      r = Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "parser.supported.test"), Whois::Record::Part.new(:body => "", :host => "parser.undefined.test")])
      described_class.new(r).created_on.should == :created_on_supported
      r = Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "parser.undefined.test"), Whois::Record::Part.new(:body => "", :host => "parser.supported.test")])
      described_class.new(r).created_on.should == :created_on_supported
    end

    it "raises unless at least one is supported" do
      lambda do
        r = Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "parser.unsupported.test"), Whois::Record::Part.new(:body => "", :host => "parser.unsupported.test")])
        described_class.new(r).created_on
      end.should raise_error(Whois::AttributeNotSupported)
    end

    it "raises when parsers are undefined" do
      lambda do
        r = Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "parser.undefined.test"), Whois::Record::Part.new(:body => "", :host => "parser.undefined.test")])
        described_class.new(r).created_on
      end.should raise_error(Whois::AttributeNotImplemented)
    end

    it "raises when zero parts" do
      lambda do
        r = Whois::Record.new(nil, [])
        described_class.new(r).created_on
      end.should raise_error(Whois::ParserError, /the Record is empty/)
    end

    it "does not delegate unknown properties" do
      lambda do
        r = Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "parser.undefined.test")])
        described_class.new(r).unknown_method
      end.should raise_error(NoMethodError)
    end
  end


  describe "#parsers" do
    it "returns 0 parsers when 0 parts" do
      record = Whois::Record.new(nil, [])
      parser = described_class.new(record)
      parser.parsers.should have(0).parsers
      parser.parsers.should == []
    end

    it "returns 1 parser when 1 part" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "whois.nic.it")])
      parser = described_class.new(record)
      parser.parsers.should have(1).parsers
    end

    it "returns 2 parsers when 2 part" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "whois.crsnic.net"), Whois::Record::Part.new(:body => nil, :host => "whois.nic.it")])
      parser = described_class.new(record)
      parser.parsers.should have(2).parsers
    end

    it "initializes the parsers in reverse order" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "whois.crsnic.net"), Whois::Record::Part.new(:body => nil, :host => "whois.nic.it")])
      parser = described_class.new(record)
      parser.parsers[0].should be_a(Whois::Record::Parser::WhoisNicIt)
      parser.parsers[1].should be_a(Whois::Record::Parser::WhoisCrsnicNet)
    end

    it "returns the host parser when the part is supported" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "whois.nic.it")])
      parser = described_class.new(record)
      parser.parsers.first.should be_a(Whois::Record::Parser::WhoisNicIt)
    end

    it "returns the Blank parser when the part is not supported" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "missing.nic.it")])
      parser = described_class.new(record)
      parser.parsers.first.should be_a(Whois::Record::Parser::Blank)
    end
  end

  describe "#property_any_supported?" do
    it "returns false when 0 parts" do
      record = Whois::Record.new(nil, [])
      described_class.new(record).property_any_supported?(:disclaimer).should be_false
    end

    it "returns true when 1 part supported" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(host: "whois.nic.it")])
      described_class.new(record).property_any_supported?(:disclaimer).should be_true
    end

    it "returns false when 1 part supported" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(host: "missing.nic.it")])
      described_class.new(record).property_any_supported?(:disclaimer).should be_false
    end

    it "returns true when 2 parts" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(host: "whois.crsnic.net"), Whois::Record::Part.new(host: "whois.nic.it")])
      described_class.new(record).property_any_supported?(:disclaimer).should be_true
    end

    it "returns true when 1 part supported 1 part not supported" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(host: "missing.nic.it"), Whois::Record::Part.new(host: "whois.nic.it")])
      described_class.new(record).property_any_supported?(:disclaimer).should be_true
    end
  end


  describe "#contacts" do
    class Whois::Record::Parser::Contacts1Test < Whois::Record::Parser::Base
    end

    class Whois::Record::Parser::Contacts2Test < Whois::Record::Parser::Base
      property_supported(:technical_contacts)   { ["p2-t1"] }
      property_supported(:admin_contacts)       { ["p2-a1"] }
      property_supported(:registrant_contacts)  { [] }
    end

    class Whois::Record::Parser::Contacts3Test< Whois::Record::Parser::Base
      property_supported(:technical_contacts)   { ["p3-t1"] }
    end

    it "returns an empty array when 0 parts" do
      record = Whois::Record.new(nil, [])
      parser = described_class.new(record)
      parser.contacts.should == []
    end

    it "returns an array of contact when 1 part is supported" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "contacts2.test")])
      parser = described_class.new(record)
      parser.contacts.should have(2).contacts
      parser.contacts.should == %w( p2-a1 p2-t1 )
    end

    it "returns an array of contact when 1 part is not supported" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "contacts1.test")])
      parser = described_class.new(record)
      parser.contacts.should have(0).contacts
      parser.contacts.should == %w()
    end

    it "merges the contacts and returns an array of contact when 2 parts" do
      record = Whois::Record.new(nil, [Whois::Record::Part.new(:body => nil, :host => "contacts2.test"), Whois::Record::Part.new(:body => nil, :host => "contacts3.test")])
      parser = described_class.new(record)
      parser.contacts.should have(3).contacts
      parser.contacts.should == %w( p3-t1 p2-a1 p2-t1 )
    end
  end


  describe "#changed?" do
    it "raises if the argument is not an instance of the same class" do
      lambda do
        described_class.new(record).changed?(Object.new)
      end.should raise_error

      lambda do
        described_class.new(record).changed?(described_class.new(record))
      end.should_not raise_error
    end
  end

  describe "#unchanged?" do
    it "raises if the argument is not an instance of the same class" do
      lambda do
        described_class.new(record).unchanged?(Object.new)
      end.should raise_error

      lambda do
        described_class.new(record).unchanged?(described_class.new(record))
      end.should_not raise_error
    end

    it "returns true if self and other references the same object" do
      instance = described_class.new(record)
      instance.unchanged?(instance).should be_true
    end

    it "returns false if parser and other.parser have different number of elements" do
      instance = described_class.new(Whois::Record.new(nil, []))
      other    = described_class.new(Whois::Record.new(nil, [Whois::Record::Part.new(:body => "", :host => "foo.example.test")]))
      instance.unchanged?(other).should be_false
    end

    it "returns true if parsers and other.parsers have 0 elements" do
      instance = described_class.new(Whois::Record.new(nil, []))
      other    = described_class.new(Whois::Record.new(nil, []))
      instance.unchanged?(other).should be_true
    end


    it "returns true if every parser in self marches the corresponding parser in other" do
      instance = described_class.new(Whois::Record.new(nil, [Whois::Record::Part.new(:body => "hello", :host => "foo.example.test"), Whois::Record::Part.new(:body => "hello", :host => "bar.example.test")]))
      other    = described_class.new(Whois::Record.new(nil, [Whois::Record::Part.new(:body => "hello", :host => "foo.example.test"), Whois::Record::Part.new(:body => "hello", :host => "bar.example.test")]))

      instance.unchanged?(other).should be_true
    end

    it "returns false unless every parser in self marches the corresponding parser in other" do
      instance = described_class.new(Whois::Record.new(nil, [Whois::Record::Part.new(:body => "hello", :host => "foo.example.test"), Whois::Record::Part.new(:body => "world", :host => "bar.example.test")]))
      other    = described_class.new(Whois::Record.new(nil, [Whois::Record::Part.new(:body => "hello", :host => "foo.example.test"), Whois::Record::Part.new(:body => "baby!", :host => "bar.example.test")]))

      instance.unchanged?(other).should be_false
    end
  end

  describe "#response_incomplete?" do
    it "returns false when all parts are complete" do
      i = parsers("defined-false", "defined-false")
      i.response_incomplete?.should == false
    end

    it "returns true when at least one part is incomplete" do
      i = parsers("defined-false", "defined-true")
      i.response_incomplete?.should == true

      i = parsers("defined-true", "defined-false")
      i.response_incomplete?.should == true
    end
  end

  describe "#response_throttled?" do
    it "returns false when all parts are not throttled" do
      i = parsers("defined-false", "defined-false")
      i.response_throttled?.should == false
    end

    it "returns true when at least one part is throttled" do
      i = parsers("defined-false", "defined-true")
      i.response_throttled?.should == true

      i = parsers("defined-true", "defined-false")
      i.response_throttled?.should == true
    end
  end

  describe "#response_unavailable?" do
    it "returns false when all parts are available" do
      i = parsers("defined-false", "defined-false")
      i.response_unavailable?.should == false
    end

    it "returns true when at least one part is unavailable" do
      i = parsers("defined-false", "defined-true")
      i.response_unavailable?.should == true

      i = parsers("defined-true", "defined-false")
      i.response_unavailable?.should == true
    end
  end


  private

  class Whois::Record::Parser::ResponseDefinedTrueTest < Whois::Record::Parser::Base
    def response_incomplete?
      true
    end
    def response_throttled?
      true
    end
    def response_unavailable?
      true
    end
  end

  class Whois::Record::Parser::ResponseDefinedFalseTest < Whois::Record::Parser::Base
    def response_incomplete?
      false
    end
    def response_throttled?
      false
    end
    def response_unavailable?
      false
    end
  end

  class Whois::Record::Parser::ResponseUndefinedTest < Whois::Record::Parser::Base
  end

  def parsers(*types)
    described_class.new(Whois::Record.new(nil, types.map { |type| Whois::Record::Part.new(:body => "", :host => "response-#{type}.test") }))
  end

end
