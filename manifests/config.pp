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
        environment => [
          "K3S_TOKEN=${token_secret}"
        ],
        timeout     => 600
      }
      # this is the exporter resource, with the ip details, https://www.puppet.com/docs/puppet/7/lang_exported.html
      @@exec { 'join-cluster':
        command     => "${k3s::binary_path} server --server ${::ipaddress}:6443",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${token_secret}"
        ],
        timeout     => 600
      }
      @@exec { 'node-join-cluster':
        command     => "${k3s::binary_path} agent --server ${::ipaddress}:6443",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${token_secret}"
        ],
        timeout     => 600
      }
    }

    'joining': {
      Exec <<| title == 'join-cluster' |>>
    }

    'node': {
      Exec <<| title == 'node-join-cluster' |>>
    }

    default: {
      fail('No valid configuration type provided.')
    }
  }
}
