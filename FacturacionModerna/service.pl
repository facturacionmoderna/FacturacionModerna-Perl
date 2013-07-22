#!/usr/bin/perl -w
package FacturacionModerna::Service;
use warnings;
use strict;

use Module::Load;
use SOAP::Lite( +trace => 'all', maptype => {} );
use POSIX qw(strftime);use MIME::Base64;
use Data::Dumper;
use Class::Struct;
use XML::LibXML;

sub new(){
  my ($class) = @_;
  my $self = {
    _url => undef,
    _xml => undef,
    _txt => undef,
    _pdf => undef,
    _png => undef,
    _pdf => undef,
    _uuid => undef,
    _rfc_emisor => undef,
    _user_id => undef,
    _user_password => undef,
    _generar_cbb => 'false',
    _generar_txt => 'false',
    _generar_pdf => 'false'
  };
  bless($self, $class);
  return $self;
}

# Accesors
sub url {
  my ( $self, $url ) = @_;
  $self->{_url} = $url if defined($url);
  return $self->{_url};
}

sub xml {
  my ( $self ) = @_;
  return $self->{_xml};
}

sub uuid {
  my ( $self ) = @_;
  return $self->{_uuid};
}

sub emisorRFC {
  my ( $self, $emisor_rfc) = @_;
  $self->{_emisor_rfc} = $emisor_rfc if defined($emisor_rfc);
  return $self->{_emisor_rfc};
}

sub UserID {
  my ( $self, $user_id) = @_;
  $self->{_user_id} = $user_id if defined($user_id);
  return $self->{_user_id};
}

sub UserPass {
  my ( $self, $user_password) = @_;
  $self->{_user_password} = $user_password if defined($user_password);
  return $self->{_user_password};
}

sub generarCBB {
  my ( $self, $generar_cbb) = @_;
  $self->{_generar_cbb} = $generar_cbb if defined($generar_cbb);
  return $self->{_generar_cbb};
}

sub generarTXT {
  my ( $self, $generar_txt) = @_;
  $self->{_generar_txt} = $generar_txt if defined($generar_txt);
  return $self->{_generar_txt};
}

sub generarPDF {
  my ( $self, $generar_pdf) = @_;
  $self->{_generar_pdf} = $generar_pdf if defined($generar_pdf);
  return $self->{_generar_pdf};
}

sub generarParametros {
  my ( $self, $opciones) = @_;
  my $params = {};
  $params->{'emisorRFC'} = $self->emisorRFC;
  $params->{'UserID'} = $self->UserID;
  $params->{'UserPass'} = $self->UserPass;
  #$params->{'generarCBB'} = $self->generarCBB;
  #$params->{'generarTXT'} = $self->generarTXT;
  #$params->{'generarPDF'} = $self->generarPDF;
  my %parametros = (%$params, %$opciones);
  return \%parametros;
}

sub timbrar(){
  my ( $self, $cfdi, $opciones) = @_;
  my $parametros = $self->generarParametros($opciones);
  my $encoded = encode_base64($cfdi);
  my $soap = SOAP::Lite->service($self->url);

  # Agregamos a los parámetros el contenido a timbrar
  $parametros->{'text2CFDI'} = $encoded;
  our $response = $soap->requestTimbrarCFDI($parametros);

  # Obtener el XML
  my $cfdi_xml = decode_base64($response->{'xml'});
  my $parser = XML::LibXML->new();
  my $xdoc   = $parser->parse_string($cfdi_xml);

  # Obtener el UUID del XML
  my $xpc = XML::LibXML::XPathContext->new($xdoc);
  $xpc->registerNs("tfd", "http://www.sat.gob.mx/TimbreFiscalDigital");
  my @tfd = $xpc->findnodes('//tfd:TimbreFiscalDigital');

  my $uuid = @tfd[0]->getAttribute('UUID');
  $self->{_xml} = $cfdi_xml;
  $self->{_uuid} = $uuid;

  $self->{_txt} = decode_base64($response->{'txt'}) if defined($response->{'txt'});
  # Guardar el archivo CBB (png)
  if ($response->{'png'}) {
    my $out;
    open($out, '>:raw', "comprobantes/$uuid.png") or die "Unable to open: $!";
    print $out decode_base64($response->{'png'});
    close($out);
  }
  # Guardar el archivo PDF
  if ($response->{'pdf'}) {
    my $out;
    open($out, '>:raw', "comprobantes/$uuid.pdf") or die "Unable to open: $!";
    print $out decode_base64($response->{'pdf'});
    close($out);
  }
}

sub cancelar(){
  my ( $self, $uuid, $opciones) = @_;
  my $parametros = $self->generarParametros($opciones);
  my $soap = SOAP::Lite->service($self->url);

  # Agregamos a los parámetros el contenido a timbrar
  $parametros->{'uuid'} = $uuid;
  our $response = $soap->requestCancelarCFDI($parametros);
  print Dumper($response);
}


1;
