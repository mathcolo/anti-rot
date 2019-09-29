require 'digest'
require 'json'
require 'optparse'
require 'find'

FILE_IGNORE_LIST = [
    '@eaDir',
    '.DS_Store',
    '.apdisk',
    '.TemporaryItems',
]

def mode_fix(opts)
    unless opts[:store_path]
        puts 'Missing argument: --store'
        exit(1)
    end
    data = JSON.parse(File.read(opts[:store_path])) 
    puts "Using existing store at #{opts[:store_path]}..."

    data.each do |key, info|
        if info['flag'] == true
            print "Is #{key} modification OK? [y/N] "
            answer = gets.chomp
            info['flag'] = false if answer == 'y'
        end
    end
    write_data_out data, opts[:store_path]

end

def write_data_out(data, store_path)
    File.open(store_path, "w+") do |f|
        f << data.to_json
    end
end


def mode_main(opts)
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

    Find.find(opts[:scan_path]) do |f|
        if FILE_IGNORE_LIST.include? File.basename(f)
            Find.prune
        end
        next unless File.file? f # Skip directories
        sha = Digest::SHA256.file(f).hexdigest[0,32] # Truncated sha256
        if data.key?(f) && (data[f]['flag'] || sha != data[f]['sha'])
            puts "!!!!@@@@ SHA MISMATCH WARNING: for file '#{f}', known SHA256 is #{data[f]['sha']} and new SHA256 is #{sha} @@@@!!!!"
            data[f]['flag'] = true
        else
            data[f] = { 'sha' => sha, 'flag' => false }
        end

        size_estimate += 64 + f.length
        file_count += 1
        if file_count % 5000 == 0 then puts "Scanned #{file_count} files..." end
    end

    puts
    print "Finished filesystem traversal. The SHA256 store will be at least #{size_estimate} bytes, are you sure you want to write this to disk (y/N)? "
    answer = gets.chomp
    exit(0) unless answer == 'y'

    write_data_out data, opts[:store_path]

    puts 'Complete'
end

opts = {}
OptionParser.new do |opt|
  opt.on('-s', '--store PATH', 'The file path to the JSON that contains, or will contain, your hashes.') { |o| opts[:store_path] = o }
  opt.on('-d', '--scan PATH', 'The path to scan for corruption.') { |o| opts[:scan_path] = o }
  opt.on('-m', '--mode NAME', '[Run other supported modes: fix]') { |o| opts[:mode] = o }
end.parse!

if opts[:mode] == 'fix'
    mode_fix opts
else
    mode_main opts
end