require 'time'
require 'digest/sha1'
require 'openssl'
require 'base64'

module HashCash
	# The HashCash::Stamp class can be used to create and verify proof of work, so
	# called hash cash, as defined on hashcash.org.
	#
	# Basically, it creates a 'stamp', which when hashed with SHA-1 has a
	# certain amount of 0 bytes at the top.
	#
	# To create a new stamp, call the constructor with the :resource parameter
	# to specify a resource for which this stamp will be valid (e.g. an email
	# address).
	#
	# To verify a stamp, call it with a string representation of the stamp as
	# the :stamp parameter and call verify with a resource on it.
	class Stamp
		attr_reader :version, :bits, :resource, :date, :stamp_string

		STAMP_VERSION = 1

		# To construct a new HashCash::Stamp object, pass the :resource parameter
		# to it, e.g.
		#
		# s = HashCash::Stamp.new(:resource => 'hashcash@alech.de')
		#
		# This creates a 20 bit hash cash stamp, which can be retrieved using
		# the stamp_string() attribute reader method.
		#
		# Optionally, the parameters :bits and :date can be passed to the
		# method to change the number of bits the stamp is worth and the issuance
		# date (which is checked on the server for an expiry with a default
		# deviance of 2 days, pass a Time object).
		#
		# Alternatively, a stamp can be passed to the constructor by passing
		# it as a string to the :stamp parameter, e.g.
		#
		# s = HashCash::Stamp.new(:stamp => '1:20:060408:adam@cypherspace.org::1QTjaYd7niiQA/sc:ePa')
		def initialize(args)
			if ! args || (! args[:stamp] && ! args[:resource]) then
				raise ArgumentError, 'either stamp or stamp parameters needed'
			end
			# existing stamp in string format
			if args[:stamp] then
				@stamp_string = args[:stamp]
				(@version, @bits, @date, @resource, ext, @rand, @counter) \
					= args[:stamp].split(':')
				@bits = @bits.to_i
				if @version.to_i != STAMP_VERSION then
					raise ArgumentError, "incorrect stamp version #{@version}"
				end
				@date = parse_date(@date)
			# new stamp to be created
			elsif args[:resource] then
				@resource = args[:resource]
				# optional parameters: bits and date
				@bits = args[:bits] || 20
				@bits = @bits.to_i
				if args[:date] && ! args[:date].class == Time then
					raise ArgumentError, 'date needs to be a Time object'
				end
				@date = args[:date] || Time.now

				# create first part of stamp string
				random_string = Base64.encode64(OpenSSL::Random.random_bytes(12)).chomp
				first_part = "#{STAMP_VERSION}:#{@bits}:" + \
							 "#{date_to_str(@date)}:#{@resource}" + \
							 "::#{random_string}:"
				ctr = 0
				@stamp_string = nil
				while ! @stamp_string do
					test_stamp = first_part + ctr.to_s(36)
					if Digest::SHA1.digest(test_stamp).unpack('B*')[0][0,@bits].to_i == 0
						@stamp_string = test_stamp
					end
					ctr += 1
				end
			end
		end

		# Verify a stamp for a given resource or resources and a number of bits.
		# The resources parameter can either be a string for a single resource
		# or an array of strings for more than one possible resource (for example
		# if you have different email addresses and want the stamp to verify against
		# one of them).
		#
		# The method checks the resource, the time of issuance and the number of
		# 0 bits when the stamp is SHA1-hashed. It returns true if all checks
		# are successful and raises an exception otherwise.
		def verify(resources, bits = 20)
			# check for correct resource
			if resources.class != String && resources.class != Array then
				raise ArgumentError, "resource must be either String or Array"
			end
			if resources.class == String then
				resources = [ resources ]
			end
			if ! resources.include? @resource then
				raise "Stamp is not valid for the given resource(s)."
			end
			# check if difference is greater than 2 days
			if (Time.now - @date).to_i.abs > 2*24*60*60 then
				raise "Stamp is expired/not yet valid"
			end
			# check 0 bits in stamp
			if (Digest::SHA1.hexdigest(@stamp_string).hex >> (160-bits) != 0) then
				raise "Invalid stamp, not enough 0 bits"
			end
			true
		end

		# A string representation of the stamp
		def to_s
			@stamp_string
		end

		private
		# Parse the date contained in the stamp string.
		def parse_date(date)
			year  = date[0,2].to_i
			month = date[2,2].to_i
			day   = date[4,2].to_i
			# Those may not exist, but it is irrelevant as ''.to_i is 0
			hour  = date[6,2].to_i
			min   = date[8,2].to_i
			sec   = date[10,2].to_i
			Time.utc(2000 + year, month, day, hour, min, sec)
		end

		# Convert a date to the string format used in the stamps
		def date_to_str(date)
			if (date.sec == 0) && (date.hour == 0) && (date.min == 0) then
				date.strftime("%y%m%d")
			elsif (date.sec == 0) then
				date.strftime("%y%m%d%H%M")
			else
				date.strftime("%y%m%d%H%M%S")
			end
		end
	end
end
