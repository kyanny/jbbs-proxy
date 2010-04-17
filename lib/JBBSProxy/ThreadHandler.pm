package JBBSProxy::ThreadHandler;
use base qw(Tatsumaki::Handler);
__PACKAGE__->asynchronous(1);

use Tatsumaki::HTTPClient;
use Encode;
use Encode::Guess;

sub get {
    my ($self, $category, $address, $number, $option) = @_;
    my $client = Tatsumaki::HTTPClient->new;
    $client->get("http://jbbs.livedoor.jp/bbs/rawmode.cgi/$category/$address/$number/$option", $self->async_cb(sub { $self->on_response($category, $address, $number, $option, @_) }));
}

sub on_response {
    my ($self, $category, $address, $number, $option, $res) = @_;
    $self->response->content_type('text/html; charset=utf-8');

    my $content = $res->content;
    my $enc = guess_encoding($content, qw/euc-jp shift_jis/);
    if (ref $enc) {
        $content = decode($enc->name, $content);
    }

    my @labels = qw(number name email created_at body title);
    my @comments;
    my $title = '';
    for my $line (split /\n/, $content) {
        my @cols = split /<>/, $line;
        my %comment;
        @comment{@labels} = @cols;
        $title = $comment{title} if $comment{title};
        push @comments, \%comment;
    }

    $self->render('thread.html', {
        category => $category,
        address => $address,
        number => $number,
        title => $title,
        comments => \@comments,
    });
}

1;
