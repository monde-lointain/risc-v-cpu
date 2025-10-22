# Define output directory
set outputDir ../buildresults
file mkdir $outputDir

set top datapath

# Create dummy project
create_project $top ./buildresults -part xc7a35tcpg236-1 -force

puts "Adding files..."
# Read file list from list.f and add each file
set fp [open "./list1.f" r]
set file_list [split [read $fp] "\n"]
close $fp

foreach f $file_list {
    if {[string trim $f] ne ""} {
        add_files $f
    }
}

puts "Synthesizing design..."
synth_design -lint -name $top -top $top -flatten_hierarchy full 
