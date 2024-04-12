# @summary Class responsible for configurationk3s
class k3s::config (
  String $token_secret,
  Enum['init','joining'] $type,
) {
  # type as in the 'init'/first master or a 'joining' master
  case $type {
    'init': {
      exec { 'init-cluster':
        command     => "${k3s::binary_path} server --cluster-init",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environemnt => [
          "K3S_TOKEN=${token_secret}"
        ]
      }
      # this is the exporter resource, with the ip details, https://www.puppet.com/docs/puppet/7/lang_exported.html
      @@exec { 'join-cluster':
        command     => "${k3s::binary_path} server --server ${::ipaddress}:6443",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environemnt => [
          "K3S_TOKEN=${token_secret}"
        ]
      }
    }

    'joining': {
      Exec <<| |>>
    }

    default: {
      fail('No valid configuration type provided.')
    }
  }
}
