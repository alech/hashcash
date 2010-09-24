require 'test/unit'
require 'lib/hashcash'
require 'digest/sha1'

class TestHashCash < Test::Unit::TestCase
    WIKIPEDIA_EXAMPLE = '1:20:060408:adam@cypherspace.org::1QTjaYd7niiQA/sc:ePa'

	def test_instantiation
		assert_raise( ArgumentError ) { HashCash::Stamp.new }
        assert(HashCash::Stamp.new(:resource => 'testhashcash'))
        assert(HashCash::Stamp.new(:resource => 'foobar', :bits => 15))
        assert(HashCash::Stamp.new(:stamp => WIKIPEDIA_EXAMPLE))
	end

	def test_parsing
        s = HashCash::Stamp.new(:stamp => WIKIPEDIA_EXAMPLE)
        assert_equal(1, s.version.to_i)
        assert_equal(20, s.bits)
        assert_equal(2006, s.date.year)
        assert_equal(4, s.date.month)
        assert_equal(8, s.date.day)
	end

    def test_verify_errors
        s = HashCash::Stamp.new(:stamp => WIKIPEDIA_EXAMPLE)
        # wrong resource
        assert_raise( RuntimeError ) { s.verify('foo@example.org') }
        # expired
        assert_raise( RuntimeError ) { s.verify('adam@cypherspace.org') }
        # not enough 'cash'
        stamp = "1:32:" + Time.now.strftime('%y%m%d') + ':testhashcash::foobar1234:1'
        # make sure it is really not enough
        while (Digest::SHA1.hexdigest(stamp).hex >> (160-32) == 0) do
            stamp += '1'
        end
        s2 = HashCash::Stamp.new(:stamp => stamp)
        assert_raise( RuntimeError ) { s.verify('testhashcash') }
    end

    def test_create_and_verify
        s = HashCash::Stamp.new(:resource => 'testhashcash')
        assert(s.verify('testhashcash'))

        s2 = HashCash::Stamp.new(:resource => 'testhashcash', :bits => 10)
        assert(s2.verify('testhashcash', 10))

        s3 = HashCash::Stamp.new(:resource => 'testhashcash', :bits => 10, :date => Time.now)
        assert(s3.verify('testhashcash', 10))
    end
end
