#!/usr/bin/env ruby

require 'rubygems'
require 'paint'

def rainbow(freq, i)
    red   = Math.sin(freq*i + 0) * 127 + 128
    green = Math.sin(freq*i + 2*Math::PI/3) * 127 + 128
    blue  = Math.sin(freq*i + 4*Math::PI/3) * 127 + 128
    "#%02X%02X%02X" % [ red, green, blue ]
end

speed = 1.0/3
steps = 6
# line_set = (0...20)
line_set = [0, 3, 6, 9, 12, 15]
# line_set = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

line_set.each do |line|
	print Paint['  445 [seth@TestBook]', :black, rainbow(line, speed)]
	color_set = []
	(0...steps).each do |step|
		real_step = step
		pre = rainbow(line + real_step, speed)
		# post = rainbow(line + real_step + 1, speed)
		# print Paint["\u2591", post, pre]
		str = Paint[' ', nil, pre]
		color_set << str
		print str
	end
	print Paint['ruby: 2.0.0-p195    ', :black, rainbow(line + steps - 1, speed)]
	print '%3i ' % line
	puts color_set.join.inspect
	puts
end