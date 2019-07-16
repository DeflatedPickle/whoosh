use v6;
use File::Find;
use Text::Levenshtein::Damerau;
use Terminal::ANSIColor;

my $prompt = colored "~>", "green";

my @valid_cmds = Empty;
# TODO: Display the process of this loading on the right side of the shell
my $cmds = start {race for split(';', %*ENV<Path>).race {try for find dir => $_, keep-going => True {if $_.contains: <.exe> {@valid_cmds.append: split('.', split('\\', $_.path).tail).head}}}}

my %built-in = Map.new: 'cd' => sub (*@args) {
    if @args.elems > 0 {
        my $path = @args.join: ' ';

        if $path.IO.d {
            &*chdir($path);
            return;
        }
        say colored 'That isn\'t a valid directory', 'red';
        return;
    }
    say colored 'No directory was specified', 'red';
    return;
}, 'ls' => sub (*@args) {
    # TODO: Work out how many can fit per-line, table it up
    my $longest = 0;
    my @files = gather for dir $*CWD {
        if (my $chars = (my $file = $_.basename).chars) > $longest {$longest = $chars}
        take $file;
    }

    for @files {
        say $_
    }
}, 'help' => sub (*@args) {
    # TODO: Write a help page
    say 'There is no helping this one';
}, 'exit' => sub (*@args) {
    exit;
};
my $shell = start {
    say colored '"Whoosh Shell v0.1.0"', 'cyan';
    loop {
        # Get the user input and format it
        my ($cmd, @args) = split ' ', trim chomp prompt colored('['~"$*CWD"~']', 'cyan')~' '~$prompt~' ';
        # It's a built in command
        if (my $func = %built-in{$cmd}) { $func(@args) }
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
                        for @valid_cmds {my $dist = ld($cmd, $_);
                        if $dist < 2 {@sug.append: $_}}

                        say colored "'$cmd$(' '~@args.join: ' ' if @args.elems > 0)' is not a registered command$(', but these are; \''~(@sug.join: '\', \'' if @sug.elems > 0)~'\'')", 'yellow'
                    }
                }
            }
        }
    }
}
await $cmds, $shell;
await $shell;
