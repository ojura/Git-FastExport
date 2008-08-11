use strict;
use warnings;
use File::Path;
use File::Spec;
use Git;

# some data for the file content
my @data = <DATA>;

1;

# create a new, empty repository
sub new_repo {
    my ( $dir, $name ) = @_;

    # alas, this can't be done with Git.pm
    my $wc = File::Spec->rel2abs( File::Spec->catfile( $dir, $name ) );
    mkpath $wc;
    chdir $wc;
    `git-init`;
    return Git->repository( Directory => $wc );
}

# produce a text description of a given repository
sub repo_description {
    my ($repo) = @_;
    my %log;    # map sha1 to log message
    my @commits;

    # process the whole tree
    my ( $fh, $c )
        = $repo->command_output_pipe( 'log', '--pretty=format:%H-%P-%s',
        '--date-order', '--all' );
    while (<$fh>) {
        chomp;
        my ( $h, $p, $log ) = split /-/, $_, 3;
        $log{$h} = $log;
        $p =~ y/ //d;
        push @commits, $p ? "$log-$p" : $log;
    }
    $repo->command_close_pipe( $fh, $c );

    # replace SHA-1 by log name
    my $desc = join ' ', reverse @commits;
    $desc =~ s/(\w{40})/$log{$1}/g;

    return $desc;
}

# create a set of repositories from a given description
sub create_repos {
    my ( $dir, $desc ) = @_;
    my @nodes = split / /, $desc;
    my $info = { dir => $dir, repo => {}, sha1 => {} };

    for my $node (@nodes) {
        my ( $child, $parent ) = split /-/, $node;
        my @child = $child =~ /([A-Z]\d+)/g;
        my @parent = $parent =~ /([A-Z]\d+)/g if $parent;

        die "bad node description" if @child > 1 && @parent > 1;

        if ( @child > 1 ) {    # branch point
            create_linear_commit( $info, $_, $parent[0] ) for @child;
        }
        elsif ( @parent > 1 ) {    # merge point
            create_merge_commit( $info, $child[0], @parent );
        }
        else {                     # simple, linear commit
            create_linear_commit( $info, $child[0], $parent[0] );
        }
    }

    # return the repository objects
    return map { $info->{repo}{$_} } sort keys %{ $info->{repo} };
}

sub create_linear_commit {
    my ( $info, $child, $parent ) = @_;
    my $name = substr( $child, 0, 1 );

    # create the repo if needed
    my $repo = $info->{repo}{$name};
    if ( !$repo ) {
        $repo = $info->{repo}{$name} = new_repo( $info->{dir} => $name );
    }

    # checkout the parent commit
    $repo->command( 'checkout', $info->{sha1}{$parent} ) if $parent;
    my $base = File::Spec->catfile( $info->{dir}, $name );
    update_file( $base, $name );
    $repo->command( 'add', $name );
    $repo->command( 'commit', '-m', $child );
    sleep 1;
}

sub create_merge_commit {

}

sub update_file {
    my ($file) = File::Spec->catfile(@_);
    open my $fh, '>', $file or die "Can't open $file: $!";
    print $fh shift @data;
    close $fh;
}

__DATA__
aieee
aiieee
awk
awkkkkkk
bam
bang
bang_eth
bap
biff
bloop
blurp
boff
bonk
clange
clank
clank_est
clash
clunk
clunk_eth
crash
crr_aaack
crraack
cr_r_a_a_ck
crunch
crunch_eth
eee_yow
flrbbbbb
glipp
glurpp
kapow
kayo
ker_plop
ker_sploosh
klonk
krunch
ooooff
ouch
ouch_eth
owww
pam
plop
pow
powie
qunckkk
rakkk
rip
slosh
sock
spla_a_t
splatt
sploosh
swa_a_p
swish
swoosh
thunk
thwack
thwacke
thwape
thwapp
touche
uggh
urkk
urkkk
vronk
whack
whack_eth
wham_eth
whamm
whap
zam
zamm
zap
zapeth
zgruppp
zlonk
zlopp
zlott
zok
zowie
zwapp
z_zwap
zzzzzwap
