package WebIrc::Core;

=head1 NAME

WebIrc::Core - TODO

=head1 SYNOPSIS

TODO

=cut

use Mojo::Base -base;
use WebIrc::Core::Connection;
use constant DEBUG => $ENV{'WIRC_DEBUG'} // 1;

=head1 ATTRIBUTES

=head2 redis

TODO

=cut

has 'redis';

=head2 current_connections

Current connections, defaults to being fetched from Redis

=cut

has 'current_connections';

=head1 METHODS

=head2 start

TODO

=cut

sub start {
  my $self = shift;
  return if $ENV{'SKIP_CONNECT'};
  $self->connections(sub {
    my $connections = shift;
    warn sprintf "[core] Starting %s connection(s)\n", int @$connections if DEBUG;
    for my $conn (@$connections) {
      $conn->connect;
    }
  })
}

=head2 connections

Connection list. Will fetch from redis or cache in current_connections

=cut

sub connections {
  my ($self,$cb) = @_;
  return $cb->($self->current_connections) if $self->current_connections;
  $self->redis->smembers('connections',
    sub {
      my ($redis, $res) = @_;
      my $connnections = [ map { WebIrc::Core::Connection->new(redis => $self->redis,id=>$_) } @$res ];
      $self->current_connections($connnections);
      $cb->($connnections);
    });
}

=head2 start_connection $cid

Start a single connection by connection id.

=cut

sub start_connection {
  my ($self,$cid)=@_;
  my $conn=WebIrc::Core::Connection->new(redis=>$self->redis,id=>$cid);
  $conn->connect;
}

=head2 add_connection

    $self->add_connection($uid, {
      host => $str, # irc_server[:port]
      nick => $str,
      user => $str,
      channels => $str, # '#foo #bar ...'
    }, $callback);

Add a new connection to redis. Will create a new connection id and
set all the keys in the %connection hash

=cut

sub add_connection {
  my ($self,$uid,$conn,$cb)=@_;
  my %errors;

  for my $name (qw/ host nick user /) {
    next if $conn->{$name};
    $errors{$name} = "$name is required.";
  }

  return $self->$cb(undef, \%errors) if keys %errors;
  return $self->redis->incr('connnections:id',sub {
    my ($redis,$connection_id)=@_;

    $self->redis->execute(
      [ sadd => "connections", $connection_id ],
      [ sadd => "user:$uid:connections", $connection_id ],
      (
        map {
          [ sadd => "connection:$connection_id:channels", $_ ];
        } split /\s+/,delete $conn->{channels}
      ),
      (
        map {
          [ set => "connection:$connection_id:$_", $conn->{$_} ],
        } keys %$conn
      ),
      sub { $self->$cb($connection_id) },
    );
  });
}

=head2 login

  $self->login({ login => $str, password => $str }, $callback);

Will call callback after authenticating the user. C<$callback> will receive
either:

  $callback->($self, $uid); # success
  $callback->($self, undef, $error); # on error

=cut

sub login {
  my($self, $params, $cb)=@_;
  my $uid;

  Mojo::IOLoop->delay(
    sub {
      $self->redis->get('user:'.$params->{login}.':uid',$_[0]->begin);
    }, sub {
      my $delay = shift;
      $uid = shift;
      return $self->$cb($uid, shift) unless $uid && $uid =~ /\d+/;
      warn "[core] Got the uid: $uid" if DEBUG;
      $self->redis->get("user:$uid:digest", $delay->begin);
    }, sub {
      my($delay,$digest)=@_;
      if(crypt($params->{password},$digest) eq $digest) {
        warn "[core] User $uid has valid password" if DEBUG;
        $self->$cb($uid);
      }
      else {
        $self->$cb(undef, 'Could not verify digest');
      }
    }
  );
}

=head2 register

TODO

=cut

sub register {
  my ($self,%user)=@_;
}

=head1 COPYRIGHT

See L<WebIrc>.

=head1 AUTHOR

Jan Henning Thorsen

Marcus Ramberg

=cut

1;
