use v6;

loop {
    my $prompt = "~>";
    # Get the user input and format it
    my ($cmd, @args) = split ' ', trim chomp prompt $prompt~' ';

    # Run the process
    my $proc = Proc::Async.new: $cmd, |@args;
    my $done = $proc.start;

    # Try to await the process
    try await $done;
}

