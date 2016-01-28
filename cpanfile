requires 'perl', '5.008001';
requires 'JSON';
requires 'LWP';
requires 'Moo';
requires 'String::Random';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

