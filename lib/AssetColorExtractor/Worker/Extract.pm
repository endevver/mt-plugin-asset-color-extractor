package AssetColorExtractor::Worker::Extract;

use strict;
use warnings;
use base qw( TheSchwartz::Worker );

use TheSchwartz::Job;
use MT::Blog;
use AssetColorExtractor::Plugin;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my $mt = MT->instance;

    my @jobs;
    push @jobs, $job;

    if ( my $key = $job->coalesce ) {
        while (
            my $job = MT::TheSchwartz->instance->find_job_with_coalescing_value(
                $class, $key
            )
        ) {
            push @jobs, $job;
        }
    }

    foreach $job (@jobs) {
        my $hash     = $job->arg;
        my $asset_id = $job->uniqkey;

        my $asset = $mt->model('asset')->load({
            id    => $asset_id,
            class => ['image', 'photo'], # Can only extract from images.
        });

        AssetColorExtractor::Plugin::extract_color( $asset )
            if $asset;

        $job->completed();
    }
}

sub grab_for    {60}
sub max_retries {100000}
sub retry_delay {60}

1;

__END__
