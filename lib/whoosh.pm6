use v6;
use Terminal::ANSIColor;

my %built-in := Map.new: 'cd' => sub {}, 'ls' => sub {}, 'help' => sub {}, 'exit' => sub {};

my $prompt = colored "~>", "green";
loop {
    # Get the user input and format it
    my ($cmd, @args) = split ' ', trim chomp prompt $prompt~' ';
    # It's a built in command
    if (my $func = %built-in{$cmd}) { $func() }
    # Run the process and await it
    else { try await (my $proc = Proc::Async.new: $cmd, |@args).start }
}
