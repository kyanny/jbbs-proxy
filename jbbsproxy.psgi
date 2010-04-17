use strict;
use warnings;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Tatsumaki::HTTPClient;

package RootHandler;
use base qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    $self->render('index.html');
}

package AboutHandler;
use base qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    $self->render('about.html');
}

package SubjectHandler;
use base qw(Tatsumaki::Handler);
__PACKAGE__->asynchronous(1);

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

package ThreadHandler;
use base qw(Tatsumaki::Handler);
__PACKAGE__->asynchronous(1);

use Encode;
use Encode::Guess;

sub get {
    my ($self, $category, $address, $number) = @_;
    my $client = Tatsumaki::HTTPClient->new;
    $client->get("http://jbbs.livedoor.jp/bbs/rawmode.cgi/$category/$address/$number/", $self->async_cb(sub { $self->on_response($category, $address, $number, @_) }));
}

sub on_response {
    my ($self, $category, $address, $number, $res) = @_;
    $self->response->content_type('text/html; charset=utf-8');

    my $content = $res->content;
    my $enc = guess_encoding($content, qw/euc-jp shift_jis/);
    if (ref $enc) {
        $content = decode($enc->name, $content);
    }

    my @labels = qw(number name email created_at body title);
    my @comments;
    for my $line (split /\n/, $content) {
        my @cols = split /<>/, $line;
        my $comment = {};
        for (my $i = 0; $i < scalar @labels; $i++) {
            my $label = $labels[$i];
            $comment->{$labels[$i]} = $cols[$i];
        }
        push @comments, $comment;
    }

    $self->render('thread.html', {
        category => $category,
        address => $address,
        number => $number,
        comments => \@comments,
    });
}

package main;
use File::Basename;

my $app = Tatsumaki::Application->new([
    '/' => 'RootHandler',
    '/about' => 'AboutHandler',
    '/http://jbbs.livedoor.jp/(\w+)/(\d+)/?' => 'SubjectHandler',
    '/http://jbbs.livedoor.jp/bbs/read\.cgi/(\w+)/(\d+)/(\d+)/?' => 'ThreadHandler',
]);

$app->template_path('template');
$app->static_path('static');

if (__FILE__ eq $0) {
    require Tatsumaki::Server;
    Tatsumaki::Server->new(port => 9999)->run($app);
} else {
    return $app;
}
