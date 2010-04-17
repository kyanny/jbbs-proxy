package JBBSProxy::SubjectHandler;
use base qw(Tatsumaki::Handler);
__PACKAGE__->asynchronous(1);

use Tatsumaki::HTTPClient;
use Encode;
use Encode::Guess;

sub get {
    my ($self, $category, $address) = @_;
    my $client = Tatsumaki::HTTPClient->new;
    $client->get("http://jbbs.livedoor.jp/$category/$address/subject.txt", $self->async_cb(sub { $self->on_response($category, $address, @_) }));
}

sub on_response {
    my ($self, $category, $address, $res) = @_;
    $self->response->content_type('text/html; charset=utf-8');

    my $content = $res->content;
    my $enc = guess_encoding($content, qw/euc-jp shift_jis/);
    if (ref $enc) {
        $content = decode($enc->name, $content);
    }

    my @threads;
    for my $line (split /\n/, $content) {
        my ($number, $title) = split /,/, $line;
        $number =~ s/\.cgi//;
        push @threads, {
            title => $title,
            number => $number,
        };
    }

    $self->render('subject.html', {
        category => $category,
        address => $address,
        threads => \@threads,
    });
}

1;
