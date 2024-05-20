# @summary Interface class to manage k3s installation
#
# This class is reponsible to call the install or uninstall classes
#
# @example
#   include k3s
#
# @example
#   class { 'k3s':
#     installation_mode => 'binary',
#     binary_path       => '/home/john-doe/bin/k3s',
#   }
class k3s (
  Enum['present', 'absent'] $ensure,
  Enum['script', 'binary'] $installation_mode,
  String $binary_version,
  String $binary_path,
  String $token_secret,
  Enum['init', 'joining', 'node'] $type,
  Array[String] $tls_san = [],
  Enum['file', 'absent'] $kube_vip_file = file,
) {
  if $installation_mode == 'binary' and (!$binary_path or !$binary_version) {
    fail('The vars $binary_version and $binary_path must be set when using the \
      binary installation mode.')
  }

  if $ensure == 'present' {
    include k3s::install
    include k3s::config
  } else {
    include k3s::uninstall
  }
}
