#!perl -T
use strict;
use Test::More;
use lib ".";

my @modules = qw<
    RackMan
    RackMan::Config
    RackMan::Device
    RackMan::Device::PDU
    RackMan::Device::PDU::APC_RackPDU
    RackMan::Device::Server
    RackMan::Device::Server::HP_ProLiant
    RackMan::Device::Switch
    RackMan::Device::Switch::Cisco_Catalyst
    RackMan::Device::VM
    RackMan::File
    RackMan::Format::Bacula
    RackMan::Format::Cacti
    RackMan::Format::DHCP
    RackMan::Format::Generic
    RackMan::Format::Kickstart
    RackMan::Format::LDAP
    RackMan::Format::Nagios
    RackMan::Format::PXE
    RackMan::SCM
    RackMan::Tasks
    RackMan::Template
    RackMan::Types
    RackMan::Utils
    RackTables::Schema
    RackTables::Types
>;

plan tests => ~~@modules;

use_ok($_) or print "Bail out!\n" for @modules;

diag( "Testing RackMan $RackMan::VERSION, Perl $], $^X" );
