use v6;
use Terminal::ANSIColor;

my %built-in := Map.new: 'cd' => sub {}, 'ls' => sub {}, 'help' => sub {}, 'exit' => sub {};

my $prompt = colored "~>", "green";

say "Whoosh Shell v0.1.0";
# split ';', %*ENV<Path>;
loop {
    # Get the user input and format it
    my ($cmd, @args) = split ' ', trim chomp prompt $prompt~' ';
    # It's a built in command
    if (my $func = %built-in{$cmd}) { $func() }
    # Run the process and await it
    else {
        try {
            await (my $proc = Proc::Async.new: $cmd, |@args).start;
            CATCH {
                default {
                    say colored "'$cmd {@args.join: ' '}' is not a registered command", 'yellow'
                }
            }
        }
    }
}
