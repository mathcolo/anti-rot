require 'digest'
require 'json'
require 'optparse'

opts = {}
OptionParser.new do |opt|
  opt.on('-s', '--store PATH', 'The file path to the JSON that contains, or will contain, your MD5s.') { |o| opts[:store_path] = o }
  opt.on('-d', '--scan PATH', 'The path to scan for corruption.') { |o| opts[:scan_path] = o }
end.parse!

unless opts[:store_path]
    puts 'Missing argument: --store'
    exit(1)
end
unless opts[:scan_path]
    puts 'Missing argument: --scan'
    exit(1)
end

if File.file? opts[:store_path]
    data = JSON.parse(File.read(opts[:store_path])) 
    puts "Using existing store at #{opts[:store_path]}..."
    puts
else
    data = {}
    puts 'Store does not yet exist; creating a new one'
end

unless File.directory? opts[:scan_path]
    puts "#{opts[:scan_path]} is not a valid directory to scan."
    exit(1)
end

puts 'Beginning filesystem traversal...any detected corruption will print below.'
puts

file_count = 0
size_estimate = 0

files = Dir.glob("#{opts[:scan_path].chomp('/')}/**/*").each do |f|
    next unless File.file? f # Skip directories
    md5 = Digest::MD5.file f
    if data.key?(f) && (data[f]['flag'] || md5 != data[f]['md5'])
        puts "!!!!@@@@ MD5 MISMATCH WARNING: for file '#{f}', known md5 is #{data[f]['md5']} and new md5 is #{md5} @@@@!!!!"
        data[f]['flag'] = true
    else
        data[f] = { 'md5' => md5, 'flag' => false }
    end

    size_estimate += 32 + f.length
    file_count += 1
    if file_count % 5000 == 0 then puts "Scanned #{file_count} files..." end
end

puts
print "Finished filesystem traversal. The md5 store will be at least #{size_estimate} bytes, are you sure you want to write this to disk (y/N)? "
answer = gets.chomp
exit(0) unless answer == 'y'

File.open(opts[:store_path], "w+") do |f|
    f << data.to_json
end

puts 'Complete'
