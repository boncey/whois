require 'test_helper'
require 'whois/answer/parser/whois.tld.ee'

class AnswerParserWhoisTldEeTest < Whois::Answer::Parser::TestCase

  def setup
    @klass  = Whois::Answer::Parser::WhoisTldEe
    @host   = "whois.tld.ee"
  end

  def test_status
    parser    = @klass.new(load_part('registered.txt'))
    expected  = :registered
    assert_equal  expected, parser.status
    assert_equal  expected, parser.instance_eval { @status }

    parser    = @klass.new(load_part('available.txt'))
    expected  = :available
    assert_equal  expected, parser.status
    assert_equal  expected, parser.instance_eval { @status }
  end

  def test_available?
    parser    = @klass.new(load_part('registered.txt'))
    expected  = false
    assert_equal  expected, parser.available?
    assert_equal  expected, parser.instance_eval { @available }

    parser    = @klass.new(load_part('available.txt'))
    expected  = true
    assert_equal  expected, parser.available?
    assert_equal  expected, parser.instance_eval { @available }
  end

  def test_registered?
    parser    = @klass.new(load_part('registered.txt'))
    expected  = true
    assert_equal  expected, parser.registered?
    assert_equal  expected, parser.instance_eval { @registered }

    parser    = @klass.new(load_part('available.txt'))
    expected  = false
    assert_equal  expected, parser.registered?
    assert_equal  expected, parser.instance_eval { @registered }
  end


  def test_created_on
    parser    = @klass.new(load_part('registered.txt'))
    expected  = Time.parse("2010-07-04 07:10:32")
    assert_equal  expected, parser.created_on
    assert_equal  expected, parser.instance_eval { @created_on }

    parser    = @klass.new(load_part('available.txt'))
    expected  = nil
    assert_equal  expected, parser.created_on
    assert_equal  expected, parser.instance_eval { @created_on }
  end

  def test_updated_on
    parser    = @klass.new(load_part('registered.txt'))
    expected  = Time.parse("2010-12-10 13:37:11")
    assert_equal  expected, parser.updated_on
    assert_equal  expected, parser.instance_eval { @updated_on }

    parser    = @klass.new(load_part('available.txt'))
    expected  = nil
    assert_equal  expected, parser.updated_on
    assert_equal  expected, parser.instance_eval { @updated_on }
  end

  def test_expires_on
    parser    = @klass.new(load_part('registered.txt'))
    expected  = Time.parse("2011-12-10")
    assert_equal  expected, parser.expires_on
    assert_equal  expected, parser.instance_eval { @expires_on }

    parser    = @klass.new(load_part('available.txt'))
    expected  = nil
    assert_equal  expected, parser.expires_on
    assert_equal  expected, parser.instance_eval { @expires_on }
  end
  
  def test_registrar
    parser    = @klass.new(load_part('registered.txt'))
    expected  = 'fraktal'
    assert_equal  expected, parser.registrar
    assert_equal  expected, parser.instance_eval { @registrar }

    parser    = @klass.new(load_part('available.txt'))
    expected  = nil
    assert_equal  expected, parser.registrar
    assert_equal  expected, parser.instance_eval { @registrar }
  end
  
  def test_admin_contact
    parser    = @klass.new(load_part('registered.txt'))
    result    = parser.admin_contact
    assert_instance_of Whois::Answer::Contact,    result
    assert_equal "CID:FRAKTAL:7",                 result.id
    assert_equal "Tõnu Runnel",                   result.name
    assert_equal "Fraktal OÜ",                    result.organization
    
    parser    = @klass.new(load_part('available.txt'))
    assert_nil  parser.admin_contact
  end
  
  def test_registrant_contact
    parser    = @klass.new(load_part('registered.txt'))
    result    = parser.registrant_contact
    assert_instance_of Whois::Answer::Contact,    result
    assert_equal "CID:FRAKTAL:1",                 result.id
    assert_equal "Priit Haamer",                  result.name
    assert_nil result.organization
    
    parser    = @klass.new(load_part('available.txt'))
    assert_nil  parser.registrant_contact
  end

  def test_nameservers
    parser    = @klass.new(load_part('registered.txt'))
    expected  = %w( ns3.edicy.net ns4.edicy.net )
    assert_equal  expected, parser.nameservers
    assert_equal  expected, parser.instance_eval { @nameservers }
  
    parser    = @klass.new(load_part('available.txt'))
    expected  = %w()
    assert_equal  expected, parser.nameservers
    assert_equal  expected, parser.instance_eval { @nameservers }
  end
end
