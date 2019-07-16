use v6;
use File::Find;
use Text::Levenshtein::Damerau;
use Terminal::ANSIColor;

my $prompt = colored "~>", "green";
my %built-in := {};

my @valid_cmds = Empty;
# TODO: Display the process of this loading on the right side of the shell
my $cmds = start {race for split(';', %*ENV<Path>).race {try for find dir => $_, keep-going => True {if $_.contains: <.exe> {@valid_cmds.append: split('.', split('\\', $_.path).tail).head}}}}

my $shell = start {
    say "Whoosh Shell v0.1.0";
    loop {
        # Get the user input and format it
        my ($cmd, @args) = split ' ', trim chomp prompt $prompt~' ';
        # It's a built in command
        if (my $func = %built-in{$cmd}) { $func() }
        # Run the process and await it
        else {
            try {
                # Run the process
                my $proc = Proc::Async.new: $cmd, |@args;
                # Try to await the process
                sink await $proc.start;

                CATCH {
                    default {
                        my @sug = Empty;
                        for @valid_cmds {my $dist = ld($cmd, $_); if $dist < 2 {@sug.append: $_}}

                        say colored "'$cmd$(' '~@args.join: ' ' if @args.elems > 0)' is not a registered command$(', but these are; \''~(@sug.join: '\', \'' if @sug.elems > 0)~'\'')", 'yellow'
                    }
                }
            }
        }
    }
}
%built-in = Map.new: 'cd' => {}, 'ls' => {}, 'help' => {}, 'exit' => {exit}, 'restart' => {Cancellation.new.cancel; await $shell};
await $cmds, $shell;
